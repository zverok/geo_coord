require 'singleton'

module Geo
  # @private
  module Coord::Globes # :nodoc:all
    # Notes on this module
    #
    # **Credits:**
    #
    # Most of the initial code/algo, as well as tests were initially borrowed from
    # [Graticule](https://github.com/collectiveidea/graticule).
    #
    # Algo descriptions borrowed from
    #
    # * http://www.movable-type.co.uk/scripts/latlong.html (simple)
    # * http://www.movable-type.co.uk/scripts/latlong-vincenty.html (Vincenty)
    #
    # **On naming and code style:**
    #
    # Two main methods (distance/azimuth between two points and endpoint by
    # startpoint and distance/azimuth) are named `inverse` & `direct` due
    # to solving "two main geodetic problems": https://en.wikipedia.org/wiki/Geodesy#Geodetic_problems
    #
    # Code for them is pretty "un-Ruby-ish", trying to preserve original
    # formulae as much as possible (including use of Greek names and
    # inconsistent naming of some things: "simple" solution of direct problem
    # names distance `d`, while Vincenty formula uses `s`).
    #
    class Generic
      include Singleton
      include Math

      def inverse(phi1, la1, phi2, la2)
        # See http://www.movable-type.co.uk/scripts/latlong.html
        delta_phi = phi2 - phi1
        delta_la = la2 - la1
        a = sin(delta_phi/2)**2 + cos(phi1)*cos(phi2) * sin(delta_la/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        d = r * c

        y = sin(delta_la) * cos(phi1)
        x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(delta_la)

        a = atan2(y, x)

        [d, a]
      end

      def direct(phi1, la1, d, alpha1)
        phi2 = asin( sin(phi1)*cos(d/r) +
                    cos(phi1)*sin(d/r)*cos(alpha1) )
        la2 = la1 + atan2(sin(alpha1)*sin(d/r)*cos(phi1), cos(d/r)-sin(phi1)*sin(phi2))
        [phi2, la2]
      end

      private

      def r
        self.class::RADIUS
      end
    end

    class Earth < Generic
      # All in SI units (metres)
      RADIUS = 6378135
      MAJOR_AXIS = 6378137
      MINOR_AXIS = 6356752.3142
      F = (MAJOR_AXIS - MINOR_AXIS) / MAJOR_AXIS

      VINCENTY_MAX_ITERATIONS = 20
      VINCENTY_TOLERANCE = 1e-12

      def inverse(phi1, la1, phi2, la2)
        # Vincenty formula
        # See http://www.movable-type.co.uk/scripts/latlong-vincenty.html
        l = la2 - la1
        u1 = atan((1-F) * tan(phi1))
        u2 = atan((1-F) * tan(phi2))
        sin_u1 = sin(u1); cos_u1 = cos(u1)
        sin_u2 = sin(u2); cos_u2 = cos(u2)

        la = l # first approximation
        la_, cosSqalpha, sin_sigma, cos_sigma, sigma, cos2sigmaM, sinla, cosla = nil

        VINCENTY_MAX_ITERATIONS.times do
          sinla = sin(la)
          cosla = cos(la)

          sin_sigma = sqrt((cos_u2*sinla) * (cos_u2*sinla) +
            (cos_u1*sin_u2-sin_u1*cos_u2*cosla) * (cos_u1*sin_u2-sin_u1*cos_u2*cosla))

          return [0, 0] if sin_sigma == 0  # co-incident points

          cos_sigma = sin_u1*sin_u2 + cos_u1*cos_u2*cosla
          sigma = atan2(sin_sigma, cos_sigma)
          sinalpha = cos_u1 * cos_u2 * sinla / sin_sigma
          cosSqalpha = 1 - sinalpha*sinalpha
          cos2sigmaM = cos_sigma - 2*sin_u1*sin_u2/cosSqalpha
          cos2sigmaM = 0 if cos2sigmaM.nan?  # equatorial line: cosSqalpha=0 (§6)

          c = F/16*cosSqalpha*(4+F*(4-3*cosSqalpha))
          la_ = la
          la = l + (1-c) * F * sinalpha *
            (sigma + c*sin_sigma*(cos2sigmaM+c*cos_sigma*(-1+2*cos2sigmaM*cos2sigmaM)))

          break if la_ && (la - la_).abs < VINCENTY_TOLERANCE
        end

        # Formula failed to converge (happens on antipodal points)
        # We'll call Haversine formula instead.
        return super if (la - la_).abs > VINCENTY_TOLERANCE

        uSq = cosSqalpha * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2)
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))
        delta_sigma = b*sin_sigma*(cos2sigmaM+b/4*(cos_sigma*(-1+2*cos2sigmaM*cos2sigmaM)-
          b/6*cos2sigmaM*(-3+4*sin_sigma*sin_sigma)*(-3+4*cos2sigmaM*cos2sigmaM)))

        s = MINOR_AXIS * a * (sigma-delta_sigma)
        alpha1 = atan2(cos_u2*sinla, cos_u1*sin_u2 - sin_u1*cos_u2*cosla)

        [s, alpha1]
      end

      def direct(phi1, la1, s, alpha1)
        sinalpha1 = sin(alpha1)
        cosalpha1 = cos(alpha1)

        tanU1 = (1-F) * tan(phi1)
        cosU1 = 1 / sqrt(1 + tanU1**2)
        sinU1 = tanU1 * cosU1
        sigma1 = atan2(tanU1, cosalpha1)
        sinalpha = cosU1 * sinalpha1
        cosSqalpha = 1 - sinalpha**2
        uSq = cosSqalpha * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2);
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))

        sigma = s / (MINOR_AXIS*a)
        sigma_ = nil

        begin
            cos2sigmaM = cos(2*sigma1 + sigma);
            sinsigma = sin(sigma);
            cossigma = cos(sigma);
            delta_sigma = b*sinsigma*(cos2sigmaM+b/4*(cossigma*(-1+2*cos2sigmaM**2)-
                b/6*cos2sigmaM*(-3+4*sinsigma**2)*(-3+4*cos2sigmaM**2)))
            sigma_ = sigma
            sigma = s / (MINOR_AXIS*a) + delta_sigma
        end while (sigma-sigma_).abs > 1e-12

        tmp = sinU1*sinsigma - cosU1*cossigma*cosalpha1
        phi2 = atan2(sinU1*cossigma + cosU1*sinsigma*cosalpha1, (1-F)*sqrt(sinalpha**2 + tmp**2))
        la = atan2(sinsigma*sinalpha1, cosU1*cossigma - sinU1*sinsigma*cosalpha1)
        c = F/16*cosSqalpha*(4+F*(4-3*cosSqalpha))
        l = la - (1-c) * F * sinalpha *
            (sigma + c*sinsigma*(cos2sigmaM+c*cossigma*(-1+2*cos2sigmaM*cos2sigmaM)))

        la2 = (la1+l+3*PI) % (2*PI) - PI # normalise to -PI...+PI

        [phi2, la2]
      end
    end
  end
end
