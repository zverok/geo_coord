# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

# Geo::Coord is Ruby's library for handling [lat, lng] pairs of
# geographical coordinates. It provides most of basic functionality
# you may expect (storing and representing coordinate pair), as well
# as some geodesy math, like distances and azimuth, and comprehensive
# parsing/formatting features.
#
# See +Geo::Coord+ class docs for full description and usage examples.
#
module Geo
  # Geo::Coord is main class of Geo module, representing
  # +(latitude, longitude)+ pair. It stores coordinates in floating-point
  # degrees form, provides access to coordinate components, allows complex
  # formatting and parsing of coordinate pairs and performs geodesy
  # calculations in standard WGS-84 coordinate reference system.
  #
  # == Examples of usage
  #
  # Creation:
  #
  #    # From lat/lng pair:
  #    g = Geo::Coord.new(50.004444, 36.231389)
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  #    # Or using keyword arguments form:
  #    g = Geo::Coord.new(lat: 50.004444, lng: 36.231389)
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  #    # Keyword arguments also allow creation of Coord from components:
  #    g = Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N', lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  # For parsing API responses you'd like to use +from_h+,
  # which accepts String and Symbol keys, any letter case,
  # and knows synonyms (lng/lon/longitude):
  #
  #    g = Geo::Coord.from_h('LAT' => 50.004444, 'LON' => 36.231389)
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  # For math, you'd probably like to be able to initialize
  # Coord with radians rather than degrees:
  #
  #    g = Geo::Coord.from_rad(0.8727421884291233, 0.6323570306208558)
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  # There's also family of parsing methods, with different applicability:
  #
  #    # Tries to parse (lat, lng) pair:
  #    g = Geo::Coord.parse_ll('50.004444, 36.231389')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  #    # Tries to parse degrees/minutes/seconds:
  #    g = Geo::Coord.parse_dms('50° 0′ 16″ N, 36° 13′ 53″ E')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  #    # Tries to do best guess:
  #    g = Geo::Coord.parse('50.004444, 36.231389')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #    g = Geo::Coord.parse('50° 0′ 16″ N, 36° 13′ 53″ E')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  #    # Allows user to provide pattern:
  #    g = Geo::Coord.strpcoord('50.004444, 36.231389', '%lat, %lng')
  #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
  #
  # Having Coord object, you can get its properties:
  #
  #    g = Geo::Coord.new(50.004444, 36.231389)
  #    g.lat # => 50.004444
  #    g.latd # => 50 -- latitude degrees
  #    g.lath # => N -- latitude hemisphere
  #    g.lngh # => E -- longitude hemishpere
  #    g.phi  # => 0.8727421884291233 -- longitude in radians
  #    g.latdms # => [50, 0, 15.998400000011316, "N"]
  #    # ...and so on
  #
  # Format and convert it:
  #
  #    g.to_s # => "50.004444,36.231389"
  #    g.strfcoord('%latd°%latm′%lats″%lath %lngd°%lngm′%lngs″%lngh')
  #    # => "50°0′16″N 36°13′53″E"
  #
  #    g.to_h(lat: 'LAT', lng: 'LON') # => {'LAT'=>50.004444, 'LON'=>36.231389}
  #
  # Do simple geodesy math:
  #
  #    kharkiv = Geo::Coord.new(50.004444, 36.231389)
  #    kyiv = Geo::Coord.new(50.45, 30.523333)
  #
  #    kharkiv.distance(kyiv) # => 410211.22377421556
  #    kharkiv.azimuth(kyiv) # => 279.12614358262067
  #    kharkiv.endpoint(410_211, 280) # => #<Geo::Coord 50.505975,30.531283>
  #
  class Coord
    # Latitude, degrees, signed float.
    attr_reader :lat

    # Longitude, degrees, signed float.
    attr_reader :lng

    alias latitude lat
    alias longitude lng
    alias lon lng

    class << self
      # @private
      LAT_KEYS = %i[lat latitude].freeze # :nodoc:
      # @private
      LNG_KEYS = %i[lng lon long longitude].freeze # :nodoc:

      # Creates Coord from hash, containing latitude and longitude.
      #
      # This methos designed as a way for parsing responses from APIs and
      # databases, so, it tries to be pretty liberal on its input:
      # - accepts String or Symbol keys;
      # - accepts any letter case;
      # - accepts several synonyms for latitude ("lat" and "latitude")
      #   and longitude ("lng", "lon", "long", "longitude").
      #
      #    g = Geo::Coord.from_h('LAT' => 50.004444, longitude: 36.231389)
      #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
      #
      def from_h(hash)
        h = hash.map { |k, v| [k.to_s.downcase.to_sym, v] }.to_h
        lat = h.values_at(*LAT_KEYS).compact.first or
          raise(ArgumentError, "No latitude value found in #{hash}")
        lng = h.values_at(*LNG_KEYS).compact.first or
          raise(ArgumentError, "No longitude value found in #{hash}")

        new(lat, lng)
      end

      # Creates Coord from φ and λ (latitude and longitude in radians).
      #
      #    g = Geo::Coord.from_rad(0.8727421884291233, 0.6323570306208558)
      #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
      #
      def from_rad(phi, la)
        new(phi * 180 / Math::PI, la * 180 / Math::PI)
      end

      # @private
      INT_PATTERN = '[-+]?\d+' # :nodoc:
      # @private
      UINT_PATTERN = '\d+' # :nodoc:
      # @private
      FLOAT_PATTERN = '[-+]?\d+(?:\.\d*)?' # :nodoc:
      # @private
      UFLOAT_PATTERN = '\d+(?:\.\d*)?' # :nodoc:

      # @private
      DEG_PATTERN = '[ °d]' # :nodoc:
      # @private
      MIN_PATTERN = "['′’m]" # :nodoc:
      # @private
      SEC_PATTERN = '["″s]' # :nodoc:

      # @private
      LL_PATTERN = /^(#{FLOAT_PATTERN})\s*[,; ]\s*(#{FLOAT_PATTERN})$/.freeze # :nodoc:

      # @private
      DMS_LATD_P = "(?<latd>#{INT_PATTERN})#{DEG_PATTERN}" # :nodoc:
      # @private
      DMS_LATM_P = "(?<latm>#{UINT_PATTERN})#{MIN_PATTERN}" # :nodoc:
      # @private
      DMS_LATS_P = "(?<lats>#{UFLOAT_PATTERN})#{SEC_PATTERN}" # :nodoc:
      # @private
      DMS_LAT_P = "#{DMS_LATD_P}\\s*#{DMS_LATM_P}\\s*#{DMS_LATS_P}\\s*(?<lath>[NS])" # :nodoc:

      # @private
      DMS_LNGD_P = "(?<lngd>#{INT_PATTERN})#{DEG_PATTERN}" # :nodoc:
      # @private
      DMS_LNGM_P = "(?<lngm>#{UINT_PATTERN})#{MIN_PATTERN}" # :nodoc:
      # @private
      DMS_LNGS_P = "(?<lngs>#{UFLOAT_PATTERN})#{SEC_PATTERN}" # :nodoc:
      # @private
      DMS_LNG_P = "#{DMS_LNGD_P}\\s*#{DMS_LNGM_P}\\s*#{DMS_LNGS_P}\\s*(?<lngh>[EW])" # :nodoc:

      # @private
      DMS_PATTERN = /^\s*#{DMS_LAT_P}\s*[,; ]\s*#{DMS_LNG_P}\s*$/x.freeze # :nodoc:

      # Parses Coord from string containing float latitude and longitude.
      # Understands several types of separators/spaces between values.
      #
      #    Geo::Coord.parse_ll('-50.004444 +36.231389')
      #    # => #<Geo::Coord 50°0'16"S 36°13'53"E>
      #
      # If parse_ll is not wise enough to understand your data, consider
      # using ::strpcoord.
      #
      def parse_ll(str)
        str.match(LL_PATTERN) do |m|
          return new(m[1].to_f, m[2].to_f)
        end
        raise ArgumentError, "Can't parse #{str} as lat, lng"
      end

      # Parses Coord from string containing latitude and longitude in
      # degrees-minutes-seconds-hemisphere format. Understands several
      # types of separators, degree, minute, second signs, as well as
      # explicit hemisphere and no-hemisphere (signed degrees) formats.
      #
      #    Geo::Coord.parse_dms('50°0′16″N 36°13′53″E')
      #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
      #
      # If parse_dms is not wise enough to understand your data, consider
      # using ::strpcoord.
      #
      def parse_dms(str)
        str.match(DMS_PATTERN) do |m|
          return new(
            latd: m[:latd], latm: m[:latm], lats: m[:lats], lath: m[:lath],
            lngd: m[:lngd], lngm: m[:lngm], lngs: m[:lngs], lngh: m[:lngh]
          )
        end
        raise ArgumentError, "Can't parse #{str} as degrees-minutes-seconds"
      end

      # Tries its best to parse Coord from string containing it (in any
      # known form).
      #
      #    Geo::Coord.parse('-50.004444 +36.231389')
      #    # => #<Geo::Coord 50°0'16"S 36°13'53"E>
      #    Geo::Coord.parse('50°0′16″N 36°13′53″E')
      #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
      #
      # If you know exact form in which coordinates are
      # provided, it may be wider to consider parse_ll, parse_dms or
      # even ::strpcoord.
      def parse(str)
        # rubocop:disable Style/RescueModifier
        parse_ll(str) rescue (parse_dms(str) rescue nil)
        # rubocop:enable Style/RescueModifier
      end

      # @private
      PARSE_PATTERNS = { # :nodoc:
        '%latd' => "(?<latd>#{INT_PATTERN})",
        '%latm' => "(?<latm>#{UINT_PATTERN})",
        '%lats' => "(?<lats>#{UFLOAT_PATTERN})",
        '%lath' => '(?<lath>[NS])',

        '%lat' => "(?<lat>#{FLOAT_PATTERN})",

        '%lngd' => "(?<lngd>#{INT_PATTERN})",
        '%lngm' => "(?<lngm>#{UINT_PATTERN})",
        '%lngs' => "(?<lngs>#{UFLOAT_PATTERN})",
        '%lngh' => '(?<lngh>[EW])',

        '%lng' => "(?<lng>#{FLOAT_PATTERN})"
      }.freeze

      # Parses +str+ into Coord with provided +pattern+.
      #
      # Example:
      #
      #   Geo::Coord.strpcoord('-50.004444/+36.231389', '%lat/%lng')
      #   # => #<Geo::Coord -50.004444,36.231389>
      #
      # List of parsing flags:
      #
      # %lat :: Full latitude, float
      # %latd :: Latitude degrees, integer, may be signed (instead of
      #          providing hemisphere info
      # %latm :: Latitude minutes, integer, unsigned
      # %lats :: Latitude seconds, float, unsigned
      # %lath :: Latitude hemisphere, "N" or "S"
      # %lng :: Full longitude, float
      # %lngd :: Longitude degrees, integer, may be signed (instead of
      #          providing hemisphere info
      # %lngm :: Longitude minutes, integer, unsigned
      # %lngs :: Longitude seconds, float, unsigned
      # %lngh :: Longitude hemisphere, "N" or "S"
      #
      def strpcoord(str, pattern)
        pattern = PARSE_PATTERNS.inject(pattern) do |memo, (pfrom, pto)|
          memo.gsub(pfrom, pto)
        end
        match = Regexp.new("^#{pattern}").match(str)
        raise ArgumentError, "Coordinates str #{str} can't be parsed by pattern #{pattern}" unless match

        new(**match.names.map { |n| [n.to_sym, _extract_match(match, n)] }.to_h)
      end

      private

      def _extract_match(match, name)
        return nil unless match[name]

        val = match[name]
        name.end_with?('h') ? val : val.to_f
      end
    end

    # Creates Coord object.
    #
    # There are three forms of usage:
    # - <tt>Coord.new(lat, lng)</tt> with +lat+ and +lng+ being floats;
    # - <tt>Coord.new(lat: lat, lng: lng)</tt> -- same as above, but
    #   with keyword arguments;
    # - <tt>Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N', lngd: 36, lngm: 13, lngs: 53, lngh: 'E')</tt> -- for
    #   cases when you have coordinates components already parsed;
    #
    # In keyword arguments form, any argument can be omitted and will be
    # replaced with 0. But you can't mix, for example, "whole" latitude
    # key +lat+ and partial longitude keys +lngd+, +lngm+ and so on.
    #
    #    g = Geo::Coord.new(50.004444, 36.231389)
    #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
    #
    #    # Or using keyword arguments form:
    #    g = Geo::Coord.new(lat: 50.004444, lng: 36.231389)
    #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
    #
    #    # Keyword arguments also allow creation of Coord from components:
    #    g = Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N', lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
    #    # => #<Geo::Coord 50°0'16"N 36°13'53"E>
    #
    #    # Providing defaults:
    #    g = Geo::Coord.new(lat: 50.004444)
    #    # => #<Geo::Coord 50°0'16"N 0°0'0"W>
    #
    def initialize(lat = nil, lng = nil, **kwargs) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @globe = Globes::Earth.instance

      # It is probably can be clearer with Ruby 2.7+ pattern-matching... or with less permissive
      # protocol :)
      kwargs = lat if lat.is_a?(Hash) && kwargs.empty? # Ruby 3.0

      case
      when lat && lng
        _init(lat, lng)
      when kwargs.key?(:lat) || kwargs.key?(:lng)
        _init(*kwargs.values_at(:lat, :lng))
      when kwargs.key?(:latd) || kwargs.key?(:lngd)
        _init_dms(**kwargs)
      else
        raise ArgumentError, "Can't create #{self.class} by provided data: (#{lat}, #{lng}, **#{kwargs}"
      end
    end

    # Compares with +other+.
    #
    # Note that no greater/lower relation is defined on Coord, so,
    # for example, you can't just sort an array of Coord.
    def ==(other)
      other.is_a?(self.class) && other.lat == lat && other.lng == lng
    end

    # Returns latitude degrees (unsigned integer).
    def latd
      lat.abs.to_i
    end

    # Returns latitude minutes (unsigned integer).
    def latm
      (lat.abs * 60).to_i % 60
    end

    # Returns latitude seconds (unsigned float).
    def lats
      (lat.abs * 3600) % 60
    end

    # Returns latitude hemisphere (upcase letter 'N' or 'S').
    def lath
      lat.positive? ? 'N' : 'S'
    end

    # Returns longitude degrees (unsigned integer).
    def lngd
      lng.abs.to_i
    end

    # Returns longitude minutes (unsigned integer).
    def lngm
      (lng.abs * 60).to_i % 60
    end

    # Returns longitude seconds (unsigned float).
    def lngs
      (lng.abs * 3600) % 60
    end

    # Returns longitude hemisphere (upcase letter 'E' or 'W').
    def lngh
      lng.positive? ? 'E' : 'W'
    end

    # Returns latitude components: degrees, minutes, seconds and optionally
    # a hemisphere:
    #
    #    # Nothern hemisphere:
    #    g = Geo::Coord.new(50.004444, 36.231389)
    #
    #    g.latdms                     # => [50, 0, 15.9984, "N"]
    #    g.latdms(hemisphere: false)  # => [50, 0, 15.9984]
    #
    #    # Southern hemisphere:
    #    g = Geo::Coord.new(-50.004444, 36.231389)
    #
    #    g.latdms                     # => [50, 0, 15.9984, "S"]
    #    g.latdms(hemisphere: false)  # => [-50, 0, 15.9984]
    #
    def latdms(hemisphere: true)
      hemisphere ? [latd, latm, lats, lath] : [latsign * latd, latm, lats]
    end

    # Returns longitude components: degrees, minutes, seconds and optionally
    # a hemisphere:
    #
    #    # Eastern hemisphere:
    #    g = Geo::Coord.new(50.004444, 36.231389)
    #
    #    g.lngdms                     # => [36, 13, 53.0004, "E"]
    #    g.lngdms(hemisphere: false)  # => [36, 13, 53.0004]
    #
    #    # Western hemisphere:
    #    g = Geo::Coord.new(50.004444, 36.231389)
    #
    #    g.lngdms                     # => [36, 13, 53.0004, "E"]
    #    g.lngdms(hemisphere: false)  # => [-36, 13, 53.0004]
    #
    def lngdms(hemisphere: true)
      hemisphere ? [lngd, lngm, lngs, lngh] : [lngsign * lngd, lngm, lngs]
    end

    # Latitude in radians. Geodesy formulae almost alwayse use greek Phi
    # for it.
    def phi
      deg2rad(lat)
    end

    alias φ phi

    # Latitude in radians. Geodesy formulae almost alwayse use greek Lambda
    # for it; we are using shorter name for not confuse with Ruby's +lambda+
    # keyword.
    def la
      deg2rad(lng)
    end

    alias λ la

    # Returns a string represent coordinates object.
    #
    #    g.inspect  # => "#<Geo::Coord 50.004444,36.231389>"
    #
    def inspect
      strfcoord(%{#<#{self.class.name} %latd°%latm'%lats"%lath %lngd°%lngm'%lngs"%lngh>})
    end

    # Returns a string representing coordinates.
    #
    #    g.to_s              # => "50°0'16\"N 36°13'53\"E"
    #    g.to_s(dms: false)  # => "50.004444,36.231389"
    #
    def to_s(dms: true)
      format = dms ? %{%latd°%latm'%lats"%lath %lngd°%lngm'%lngs"%lngh} : '%lat,%lng'
      strfcoord(format)
    end

    # Returns a two-element array of latitude and longitude.
    #
    #    g.latlng   # => [50.004444, 36.231389]
    #
    def latlng
      [lat, lng]
    end

    # Returns a two-element array of longitude and latitude (reverse order to +latlng+).
    #
    #    g.lnglat   # => [36.231389, 50.004444]
    #
    def lnglat
      [lng, lat]
    end

    # Returns hash of latitude and longitude. You can provide your keys
    # if you want:
    #
    #    g.to_h
    #    # => {:lat=>50.004444, :lng=>36.231389}
    #    g.to_h(lat: 'LAT', lng: 'LNG')
    #    # => {'LAT'=>50.004444, 'LNG'=>36.231389}
    #
    def to_h(lat: :lat, lng: :lng)
      {lat => self.lat, lng => self.lng}
    end

    # @private
    INTFLAGS = '\+' # :nodoc:
    # @private
    FLOATUFLAGS = /\.0\d+/.freeze # :nodoc:
    # @private
    FLOATFLAGS = /\+?#{FLOATUFLAGS}?/.freeze # :nodoc:

    # @private
    DIRECTIVES = { # :nodoc:
      /%(#{FLOATUFLAGS})?lats/ => proc { |m| "%<lats>#{m[1] || '.0'}f" },
      '%latm' => '%<latm>i',
      /%(#{INTFLAGS})?latds/ => proc { |m| "%<latds>#{m[1]}i" },
      '%latd' => '%<latd>i',
      '%lath' => '%<lath>s',
      /%(#{FLOATFLAGS})?lat/ => proc { |m| "%<lat>#{m[1]}f" },

      /%(#{FLOATUFLAGS})?lngs/ => proc { |m| "%<lngs>#{m[1] || '.0'}f" },
      '%lngm' => '%<lngm>i',
      /%(#{INTFLAGS})?lngds/ => proc { |m| "%<lngds>#{m[1]}i" },
      '%lngd' => '%<lngd>i',
      '%lngh' => '%<lngh>s',
      /%(#{FLOATFLAGS})?lng/ => proc { |m| "%<lng>#{m[1]}f" }
    }.freeze

    # Formats coordinates according to directives in +formatstr+.
    #
    # Each directive starts with +%+ and can contain some modifiers before
    # its name.
    #
    # Acceptable modifiers:
    # - unsigned integers: none;
    # - signed integers: <tt>+</tt> for mandatory sign printing;
    # - floats: same as integers and number of digits modifier, like
    #   <tt>.03</tt>.
    #
    # List of directives:
    #
    # %lat :: Full latitude, floating point, signed
    # %latds :: Latitude degrees, integer, signed
    # %latd :: Latitude degrees, integer, unsigned
    # %latm :: Latitude minutes, integer, unsigned
    # %lats :: Latitude seconds, floating point, unsigned
    # %lath :: Latitude hemisphere, "N" or "S"
    # %lng :: Full longitude, floating point, signed
    # %lngds :: Longitude degrees, integer, signed
    # %lngd :: Longitude degrees, integer, unsigned
    # %lngm :: Longitude minutes, integer, unsigned
    # %lngs :: Longitude seconds, floating point, unsigned
    # %lngh :: Longitude hemisphere, "E" or "W"
    #
    # Examples:
    #
    #    g = Geo::Coord.new(50.004444, 36.231389)
    #    g.strfcoord('%+lat, %+lng')
    #    # => "+50.004444, +36.231389"
    #    g.strfcoord("%latd°%latm'%lath -- %lngd°%lngm'%lngh")
    #    # => "50°0'N -- 36°13'E"
    #
    # +strfcoord+ handles seconds rounding implicitly:
    #
    #    pos = Geo::Coord.new(0.033333, 91.333333)
    #    pos.lats # => 0.599988e2
    #    pos.strfcoord('%latd %latm %.05lats') # => "0 1 59.99880"
    #    pos.strfcoord('%latd %latm %lats')  # => "0 2 0"
    #
    def strfcoord(formatstr)
      h = full_hash

      DIRECTIVES.reduce(formatstr) do |memo, (from, to)|
        memo.gsub(from) do
          to = to.call(Regexp.last_match) if to.is_a?(Proc)
          res = to % h
          res, carrymin = guard_seconds(to, res)
          h[carrymin] += 1 if carrymin
          res
        end
      end
    end

    # Calculates distance to +other+ in SI units (meters). Vincenty
    # formula is used.
    #
    #    kharkiv = Geo::Coord.new(50.004444, 36.231389)
    #    kyiv = Geo::Coord.new(50.45, 30.523333)
    #
    #    kharkiv.distance(kyiv) # => 410211.22377421556
    #
    def distance(other)
      @globe.inverse(phi, la, other.phi, other.la).first
    end

    # Calculates azimuth (direction) to +other+ in degrees. Vincenty
    # formula is used.
    #
    #    kharkiv = Geo::Coord.new(50.004444, 36.231389)
    #    kyiv = Geo::Coord.new(50.45, 30.523333)
    #
    #    kharkiv.azimuth(kyiv) # => 279.12614358262067
    #
    def azimuth(other)
      rad2deg(@globe.inverse(phi, la, other.phi, other.la).last)
    end

    # Given distance in meters and azimuth in degrees, calculates other
    # point on globe being on that direction/azimuth from current.
    # Vincenty formula is used.
    #
    #    kharkiv = Geo::Coord.new(50.004444, 36.231389)
    #    kharkiv.endpoint(410_211, 280)
    #    # => #<Geo::Coord 50°30'22"N 30°31'53"E>
    #
    def endpoint(distance, azimuth)
      phi2, la2 = @globe.direct(phi, la, distance, deg2rad(azimuth))
      Coord.from_rad(phi2, la2)
    end

    private

    LAT_RANGE_ERROR = 'Expected latitude to be between -90 and 90, %p received'
    LNG_RANGE_ERROR = 'Expected longitude to be between -180 and 180, %p received'

    def _init(lat, lng)
      lat = BigDecimal(lat.to_f, 10)
      lng = BigDecimal(lng.to_f, 10)

      raise ArgumentError, LAT_RANGE_ERROR % lat unless (-90..90).cover?(lat)
      raise ArgumentError, LNG_RANGE_ERROR % lng unless (-180..180).cover?(lng)

      @lat = lat
      @lng = lng
    end

    # @private
    LATH = {'N' => 1, 'S' => -1}.freeze # :nodoc:
    # @private
    LNGH = {'E' => 1, 'W' => -1}.freeze # :nodoc:

    def _init_dms(latd: 0, latm: 0, lats: 0, lath: nil, lngd: 0, lngm: 0, lngs: 0, lngh: nil) # rubocop:disable Metrics/AbcSize
      lat = (latd.to_d + latm.to_d / 60 + lats.to_d / 3600) * guess_sign(lath, LATH)
      lng = (lngd.to_d + lngm.to_d / 60 + lngs.to_d / 3600) * guess_sign(lngh, LNGH)

      _init(lat, lng)
    end

    def guess_sign(h, hemishperes)
      return 1 unless h

      hemishperes[h] or
        raise ArgumentError, "Unidentified hemisphere: #{h}"
    end

    def guard_seconds(pattern, result)
      m = pattern.match(/<(lat|lng)s>/)
      return result unless m && result.start_with?('60')

      carry = "#{m[1]}m".to_sym
      [pattern % {lats: 0, lngs: 0}, carry]
    end

    def latsign
      lat <=> 0
    end

    def lngsign
      lng <=> 0
    end

    def latds
      lat.to_i
    end

    def lngds
      lng.to_i
    end

    def full_hash
      {
        latd: latd,
        latds: latds,
        latm: latm,
        lats: lats,
        lath: lath,
        lat: lat,

        lngd: lngd,
        lngds: lngds,
        lngm: lngm,
        lngs: lngs,
        lngh: lngh,
        lng: lng
      }
    end

    def rad2deg(r)
      (r / Math::PI * 180 + 360) % 360
    end

    def deg2rad(d)
      d * Math::PI / 180
    end
  end
end

require_relative 'coord/globes'
