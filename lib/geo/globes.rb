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
        # Haversine formula
        # See TODO
       acos(
            sin(from.phi) * sin(to.phi) +
            cos(from.phi) * cos(to.phi) * cos(to.la - from.la)
        ) * self.class::RADIUS
      end
    end

    class Earth < Generic
      def distance(from, to)
        # Vincenty formula
        # See http://www.movable-type.co.uk/scripts/latlong-vincenty.html
        l = to.la - from.la
        u1 = atan((1-F) * tan(from.phi))
        u2 = atan((1-F) * tan(to.phi))
        sin_u1 = sin(u1); cos_u1 = cos(u1)
        sin_u2 = sin(u2); cos_u2 = cos(u2)

        la = l # first approximation
        prev_la, cosSqAlpha, sin_sigma, cos_sigma, sigma, cos2SigmaM = nil

        VINCENTY_MAX_ITERATIONS.times do
          sin_la = sin(la)
          cos_la = cos(la)

          sin_sigma = sqrt((cos_u2*sin_la) * (cos_u2*sin_la) +
            (cos_u1*sin_u2-sin_u1*cos_u2*cos_la) * (cos_u1*sin_u2-sin_u1*cos_u2*cos_la))

          return 0 if sin_sigma == 0  # co-incident points

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

        # formula failed to converge (happens on antipodal points)
        # We'll call Haversine formula instead.
        return super(from, to) if (la - prev_la).abs > VINCENTY_TOLERANCE

        uSq = cosSqAlpha * (MAJOR_AXIS**2 - MINOR_AXIS**2) / (MINOR_AXIS**2)
        a = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))
        delta_sigma = b*sin_sigma*(cos2SigmaM+b/4*(cos_sigma*(-1+2*cos2SigmaM*cos2SigmaM)-
          b/6*cos2SigmaM*(-3+4*sin_sigma*sin_sigma)*(-3+4*cos2SigmaM*cos2SigmaM)))

        MINOR_AXIS * a * (sigma-delta_sigma)
      end
      
      # All in SI units (metres)
      RADIUS = 6378135 
      MAJOR_AXIS = 6378137
      MINOR_AXIS = 6356752.3142
      F = (MAJOR_AXIS - MINOR_AXIS) / MAJOR_AXIS

      VINCENTY_MAX_ITERATIONS = 20
      VINCENTY_TOLERANCE = 1e-12
    end
  end
end
