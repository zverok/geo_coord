require 'singleton'

# Credits:
#  Most of the code/algo, as well as tests were initially borrowed from
#  [Graticule](https://github.com/collectiveidea/graticule)
#

module Geo
  module Globes
    class Generic
      include Singleton
      include Math

      def distance(from, to)
        distance_azimuth(from, to).first
      end

      def azimuth(from, to)
        (distance_azimuth(from, to).last / PI * 180 + 360) % 360
      end

      def distance_azimuth(from, to)
        # Haversine formula
        # See TODO
        d = acos(
            sin(from.phi) * sin(to.phi) +
            cos(from.phi) * cos(to.phi) * cos(to.la - from.la)
        ) * self.class::RADIUS

        y = sin(to.la - from.la) * cos(to.phi)
        x = cos(from.phi) * sin(to.phi) -
            sin(from.phi) * cos(to.phi) * cos(to.la - from.la)
        a = atan2(y, x)

        [d, a]
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

      def distance_azimuth(from, to)
        # Vincenty formula
        # See http://www.movable-type.co.uk/scripts/latlong-vincenty.html
        l = to.la - from.la
        u1 = atan((1-F) * tan(from.phi))
        u2 = atan((1-F) * tan(to.phi))
        sin_u1 = sin(u1); cos_u1 = cos(u1)
        sin_u2 = sin(u2); cos_u2 = cos(u2)

        la = l # first approximation
        prev_la, cosSqAlpha, sin_sigma, cos_sigma, sigma, cos2SigmaM, sin_la, cos_la = nil

        VINCENTY_MAX_ITERATIONS.times do
          sin_la = sin(la)
          cos_la = cos(la)

          sin_sigma = sqrt((cos_u2*sin_la) * (cos_u2*sin_la) +
            (cos_u1*sin_u2-sin_u1*cos_u2*cos_la) * (cos_u1*sin_u2-sin_u1*cos_u2*cos_la))

          return [0, 0] if sin_sigma == 0  # co-incident points

          cos_sigma = sin_u1*sin_u2 + cos_u1*cos_u2*cos_la
          sigma = atan2(sin_sigma, cos_sigma)
          sin_alpha = cos_u1 * cos_u2 * sin_la / sin_sigma
          cosSqAlpha = 1 - sin_alpha*sin_alpha
          cos2SigmaM = cos_sigma - 2*sin_u1*sin_u2/cosSqAlpha
          cos2SigmaM = 0 if cos2SigmaM.nan?  # equatorial line: cosSqAlpha=0 (§6)

          c = F/16*cosSqAlpha*(4+F*(4-3*cosSqAlpha))
          prev_la = la
          la = l + (1-c) * F * sin_alpha *
            (sigma + c*sin_sigma*(cos2SigmaM+c*cos_sigma*(-1+2*cos2SigmaM*cos2SigmaM)))

          break if prev_la && (la - prev_la).abs < VINCENTY_TOLERANCE
        end

        # Formula failed to converge (happens on antipodal points)
        # We'll call Haversine formula instead.
        return super if (la - prev_la).abs > VINCENTY_TOLERANCE

        uSq = cosSqAlpha * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2)
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))
        delta_sigma = b*sin_sigma*(cos2SigmaM+b/4*(cos_sigma*(-1+2*cos2SigmaM*cos2SigmaM)-
          b/6*cos2SigmaM*(-3+4*sin_sigma*sin_sigma)*(-3+4*cos2SigmaM*cos2SigmaM)))

        s = MINOR_AXIS * a * (sigma-delta_sigma)
        alpha1 = atan2(cos_u2*sin_la, cos_u1*sin_u2 - sin_u1*cos_u2*cos_la)
        #alpha2 = atan2(cos_u1*sin_la, -sin_u1*cos_u2+cos_u1*sin_u2*cos_la) / PI * 180

        [s, alpha1]
      end

      def endpoint(from, distance, azimuth)
        α1 = azimuth / 180 * PI
        sinα1 = sin(α1)
        cosα1 = cos(α1)

        tanU1 = (1-F) * tan(from.φ)
        cosU1 = 1 / sqrt(1 + tanU1**2)
        sinU1 = tanU1 * cosU1
        σ1 = atan2(tanU1, cosα1)
        sinα = cosU1 * sinα1
        cosSqα = 1 - sinα**2
        uSq = cosSqα * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2);
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))

        σ = distance / (MINOR_AXIS*a)
        σʹ = nil
        
        begin
            cos2σM = cos(2*σ1 + σ);
            sinσ = sin(σ);
            cosσ = cos(σ);
            Δσ = b*sinσ*(cos2σM+b/4*(cosσ*(-1+2*cos2σM**2)-
                b/6*cos2σM*(-3+4*sinσ**2)*(-3+4*cos2σM**2)))
            σʹ = σ
            σ = distance / (MINOR_AXIS*a) + Δσ
        end while (σ-σʹ).abs > 1e-12

        tmp = sinU1*sinσ - cosU1*cosσ*cosα1
        φ2 = atan2(sinU1*cosσ + cosU1*sinσ*cosα1, (1-F)*sqrt(sinα**2 + tmp**2))
        λ = atan2(sinσ*sinα1, cosU1*cosσ - sinU1*sinσ*cosα1)
        c = F/16*cosSqα*(4+F*(4-3*cosSqα))
        l = λ - (1-c) * F * sinα *
            (σ + c*sinσ*(cos2σM+c*cosσ*(-1+2*cos2σM*cos2σM)))
        λ2 = (from.λ+l+3*PI) % (2*PI) - PI # normalise to -180...+180

        Coord.from_rad(φ2, λ2)
      end
    end
  end
end
