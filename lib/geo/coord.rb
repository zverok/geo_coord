module Geo
  class Coord
    attr_reader :lat, :lng

    alias :latitude :lat
    alias :longitude :lng
    alias :lon :lng
    
    def initialize(lat, lng)
      unless (-90..90).cover?(lat)
        raise ArgumentError, "Expected latitude to be between -90 and 90, #{lat} received"
      end

      unless (-180..180).cover?(lng)
        raise ArgumentError, "Expected longitude to be between -180 and 180, #{lng} received"
      end
      
      @lat = lat
      @lng = lng
    end

    def latd
      lat.abs.to_i
    end

    def latm
      (lat.abs * 60).to_i % 60
    end

    def lats
      (lat.abs * 3600) % 3600
    end

    def lath
      lat > 0 ? 'N' : 'S'
    end

    def lngd
      lng.abs.to_i
    end

    def lngm
      (lng.abs * 60).to_i % 60
    end

    def lngs
      (lng.abs * 3600) % 60
    end

    def lngh
      lng > 0 ? 'E' : 'W'
    end

    def latdms(nohemisphere = false)
      nohemisphere ? [latsign * latd, latm, lats] : [latd, latm, lats, lath]
    end

    def lngdms(nohemisphere = false)
      nohemisphere ? [lngsign * lngd, lngm, lngs] : [lngd, lngm, lngs, lngh]
    end

    def inspect
      '#<%s %s>' % [self.class.name, to_s]
    end

    def to_s
      '%f,%f' % [lat, lng]
    end

    def to_a
      [lat, lng]
    end

    def to_h(lat: :lat, lng: :lng)
      {lat.to_sym => self.lat, lng.to_sym => self.lng}
    end

    INTFLAGS = '\+'
    FLOATUFLAGS = /\.0\d+/
    FLOATFLAGS = /\+?#{FLOATUFLAGS}/

    DIRECTIVES = {
      /%(#{INTFLAGS})?latds/ => '%<latds>\1i',
      '%latd' => '%<latd>i',
      '%latm' => '%<latm>i',
      /%(#{FLOATUFLAGS})?lats/ => proc{|m| "%<lats>#{m[1] || '.0'}f"},
      '%lath' => '%<lath>s',
      /%(#{FLOATFLAGS})?lat/ => '%<lat>\1f',

      /%(#{INTFLAGS})?lngds/ => '%<lngds>\1i',
      '%lngd' => '%<lngd>i',
      '%lngm' => '%<lngm>i',
      /%(#{FLOATUFLAGS})?lngs/ => proc{|m| "%<lngs>#{m[1] || '.0'}f"},
      '%lngh' => '%<lngh>s',
      /%(#{FLOATFLAGS})?lng/ => '%<lng>\1f',
    }

    def strfcoord(formatstr)
      DIRECTIVES.reduce(formatstr){|memo, (from, to)|
        if to.is_a?(Proc)
          memo.gsub(from){to.call(Regexp.last_match)} # scopes are hard!
        else
          memo.gsub(from, to)
        end
      } % full_hash
    end

    private

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
        lng: lng,
      }
    end
  end
end
