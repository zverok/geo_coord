require 'singleton'

module Geo
  module Globes # :nodoc:all
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
    # formulae as much as possible (including use of Greek characters and
    # inconsistent naming of some things: "simple" solution of direct problem
    # names distance `d`, while Vincenty formula uses `s`).
    #
    class Generic
      include Singleton
      include Math

      def inverse(φ1, λ1, φ2, λ2)
        # See http://www.movable-type.co.uk/scripts/latlong.html
        Δφ = φ2 - φ1
        Δλ = λ2 - λ1
        a = sin(Δφ/2)**2 + cos(φ1)*cos(φ2) * sin(Δλ/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        d = r * c

        y = sin(Δλ) * cos(φ1)
        x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)

        a = atan2(y, x)

        [d, a]
      end

      def direct(φ1, λ1, d, α1)
        φ2 = asin( sin(φ1)*cos(d/r) +
                    cos(φ1)*sin(d/r)*cos(α1) )
        λ2 = λ1 + atan2(sin(α1)*sin(d/r)*cos(φ1), cos(d/r)-sin(φ1)*sin(φ2))
        [φ2, λ2]
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

      def inverse(φ1, λ1, φ2, λ2)
        # Vincenty formula
        # See http://www.movable-type.co.uk/scripts/latlong-vincenty.html
        l = λ2 - λ1
        u1 = atan((1-F) * tan(φ1))
        u2 = atan((1-F) * tan(φ2))
        sin_u1 = sin(u1); cos_u1 = cos(u1)
        sin_u2 = sin(u2); cos_u2 = cos(u2)

        λ = l # first approximation
        λʹ, cosSqα, sin_σ, cos_σ, σ, cos2σM, sinλ, cosλ = nil

        VINCENTY_MAX_ITERATIONS.times do
          sinλ = sin(λ)
          cosλ = cos(λ)

          sin_σ = sqrt((cos_u2*sinλ) * (cos_u2*sinλ) +
            (cos_u1*sin_u2-sin_u1*cos_u2*cosλ) * (cos_u1*sin_u2-sin_u1*cos_u2*cosλ))

          return [0, 0] if sin_σ == 0  # co-incident points

          cos_σ = sin_u1*sin_u2 + cos_u1*cos_u2*cosλ
          σ = atan2(sin_σ, cos_σ)
          sinα = cos_u1 * cos_u2 * sinλ / sin_σ
          cosSqα = 1 - sinα*sinα
          cos2σM = cos_σ - 2*sin_u1*sin_u2/cosSqα
          cos2σM = 0 if cos2σM.nan?  # equatorial line: cosSqα=0 (§6)

          c = F/16*cosSqα*(4+F*(4-3*cosSqα))
          λʹ = λ
          λ = l + (1-c) * F * sinα *
            (σ + c*sin_σ*(cos2σM+c*cos_σ*(-1+2*cos2σM*cos2σM)))

          break if λʹ && (λ - λʹ).abs < VINCENTY_TOLERANCE
        end

        # Formula failed to converge (happens on antipodal points)
        # We'll call Haversine formula instead.
        return super if (λ - λʹ).abs > VINCENTY_TOLERANCE

        uSq = cosSqα * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2)
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))
        Δσ = b*sin_σ*(cos2σM+b/4*(cos_σ*(-1+2*cos2σM*cos2σM)-
          b/6*cos2σM*(-3+4*sin_σ*sin_σ)*(-3+4*cos2σM*cos2σM)))

        s = MINOR_AXIS * a * (σ-Δσ)
        α1 = atan2(cos_u2*sinλ, cos_u1*sin_u2 - sin_u1*cos_u2*cosλ)

        [s, α1]
      end

      def direct(φ1, λ1, s, α1)
        sinα1 = sin(α1)
        cosα1 = cos(α1)

        tanU1 = (1-F) * tan(φ1)
        cosU1 = 1 / sqrt(1 + tanU1**2)
        sinU1 = tanU1 * cosU1
        σ1 = atan2(tanU1, cosα1)
        sinα = cosU1 * sinα1
        cosSqα = 1 - sinα**2
        uSq = cosSqα * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2);
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))

        σ = s / (MINOR_AXIS*a)
        σʹ = nil

        begin
            cos2σM = cos(2*σ1 + σ);
            sinσ = sin(σ);
            cosσ = cos(σ);
            Δσ = b*sinσ*(cos2σM+b/4*(cosσ*(-1+2*cos2σM**2)-
                b/6*cos2σM*(-3+4*sinσ**2)*(-3+4*cos2σM**2)))
            σʹ = σ
            σ = s / (MINOR_AXIS*a) + Δσ
        end while (σ-σʹ).abs > 1e-12

        tmp = sinU1*sinσ - cosU1*cosσ*cosα1
        φ2 = atan2(sinU1*cosσ + cosU1*sinσ*cosα1, (1-F)*sqrt(sinα**2 + tmp**2))
        λ = atan2(sinσ*sinα1, cosU1*cosσ - sinU1*sinσ*cosα1)
        c = F/16*cosSqα*(4+F*(4-3*cosSqα))
        l = λ - (1-c) * F * sinα *
            (σ + c*sinσ*(cos2σM+c*cosσ*(-1+2*cos2σM*cos2σM)))

        λ2 = (λ1+l+3*PI) % (2*PI) - PI # normalise to -PI...+PI

        [φ2, λ2]
      end
    end
  end
end
