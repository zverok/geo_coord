require File.expand_path('../../spec_helper', __FILE__)

describe Geo::Coord do
  context :initialize do
    it 'is initialized by (lat, lng)' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.lat.should == 50.004444
      c.latitude.should == 50.004444
      c.phi.should == c.lat * Math::PI / 180

      c.lng.should == 36.231389
      c.lon.should == 36.231389
      c.longitude.should == 36.231389
      c.la.should == c.lng * Math::PI / 180
    end

    it "controls argument ranges" do
      lambda{Geo::Coord.new(100, 36.231389)}.should raise_error(ArgumentError)

      lambda{Geo::Coord.new(50, 360)}.should raise_error(ArgumentError)
    end

    it 'is initialized by (lat: , lng:) keyword args' do
      c = Geo::Coord.new(lat: 50.004444, lng: 36.231389)
      c.lat.should == 50.004444
      c.lng.should == 36.231389

      c = Geo::Coord.new(lat: 50.004444)
      c.lat.should == 50.004444
      c.lng.should == 0

      c = Geo::Coord.new(lng: 36.231389)
      c.lat.should == 0
      c.lng.should == 36.231389
    end

    it 'is initialized by d,m,s,h sets' do
      Geo::Coord.new(latd: 50, lngd: 36).should == Geo::Coord.new(50, 36)
      Geo::Coord.new(latd: 50, lath: 'S', lngd: 36, lngh: 'W').should == Geo::Coord.new(-50, -36)

      c = Geo::Coord.new(latd: 50, latm: 0, lats: 16,
                         lngd: 36, lngm: 13, lngs: 53)

      c.lat.should be_close(50.004444, 0.01)
      c.lng.should be_close(36.231389, 0.01)

      c = Geo::Coord.new(latd: 50, latm: 0, lats: 16)
      c.lat.should be_close(50.004444, 0.01)
      c.lng.should == 0

      c = Geo::Coord.new(lngd: 36, lngm: 13, lngs: 53)
      c.lat.should == 0
      c.lng.should be_close(36.231389, 0.01)
    end

    it 'is rasing ArgumentError when arguments are missing' do
      lambda{Geo::Coord.new()}.should raise_error(ArgumentError)
    end
  end

  context :from_h do
    it 'can be created from hash' do
      c = Geo::Coord.from_h(lat: 50.004444, lng: 36.231389)
      c.should == Geo::Coord.new(50.004444, 36.231389)
    end

    it 'supports several variants of keys' do
      c = Geo::Coord.from_h(latitude: 50.004444, longitude: 36.231389)
      c.should == Geo::Coord.new(50.004444, 36.231389)

      c = Geo::Coord.from_h(lat: 50.004444, lon: 36.231389)
      c.should == Geo::Coord.new(50.004444, 36.231389)
    end

    it 'supports string keys and different cases' do
      c = Geo::Coord.from_h('lat' => 50.004444, 'lng' => 36.231389)
      c.should == Geo::Coord.new(50.004444, 36.231389)

      c = Geo::Coord.from_h('Lat' => 50.004444, 'LNG' => 36.231389)
      c.should == Geo::Coord.new(50.004444, 36.231389)
    end
  end

  context 'parsers' do
    it 'parses lng, lat pair' do
      # ok
      Geo::Coord.parse_ll('50.004444, 36.231389').should == Geo::Coord.new(50.004444, 36.231389)
      Geo::Coord.parse_ll('50.004444,36.231389').should == Geo::Coord.new(50.004444, 36.231389)
      Geo::Coord.parse_ll('50.004444;36.231389').should == Geo::Coord.new(50.004444, 36.231389)
      Geo::Coord.parse_ll('50.004444 36.231389').should == Geo::Coord.new(50.004444, 36.231389)
      Geo::Coord.parse_ll('-50.004444 +36.231389').should == Geo::Coord.new(-50.004444, 36.231389)
      Geo::Coord.parse_ll('50 36').should == Geo::Coord.new(50, 36)

      # not ok
      lambda{Geo::Coord.parse_ll('50 36 80')}.should raise_error(ArgumentError)
      lambda{Geo::Coord.parse_ll('50.04444')}.should raise_error(ArgumentError)
    end

    it 'parses dmsh pairs' do
      Geo::Coord.parse_dms(%q{50 0' 16" N, 36 13' 53" E}).should ==
        Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N',
                       lngd: 36, lngm: 13, lngs: 53, lngh: 'E')

      Geo::Coord.parse_dms('50°0′16″N 36°13′53″E').should ==
        Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N',
                       lngd: 36, lngm: 13, lngs: 53, lngh: 'E')

      Geo::Coord.parse_dms('50°0’16″N 36°13′53″E').should ==
        Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N',
                       lngd: 36, lngm: 13, lngs: 53, lngh: 'E')

      lambda{Geo::Coord.parse_dms('50 36 80')}.should raise_error(ArgumentError)
    end

    it 'parses most reasonable choice' do
      Geo::Coord.parse('50.004444, 36.231389').should == Geo::Coord.new(50.004444, 36.231389)
      Geo::Coord.parse('50 36').should == Geo::Coord.new(50, 36)
      Geo::Coord.parse(%q{50 0' 16" N, 36 13' 53" E}).should ==
        Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N',
                       lngd: 36, lngm: 13, lngs: 53, lngh: 'E')

      Geo::Coord.parse('50').should be_nil
    end
  end

  context 'comparison' do
    it 'compares on equality' do
      c1 = Geo::Coord.new(50.004444, 36.231389)
      c2 = Geo::Coord.new(50.004444, 36.231389)
      c3 = Geo::Coord.new(-50.004444, 36.231389)
      c1.should == c2
      c1.should_not == c3
    end
  end

  context 'decomposition' do
    it 'decomposes latitude to d, m, s, h' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.latd.should == 50
      c.latm.should == 0
      c.lats.should be_close(16, 0.01)
      c.lath.should == 'N'
      c.latdms.should == [c.latd, c.latm, c.lats, c.lath]
      c.latdms(true).should == [c.latd, c.latm, c.lats]

      # Negative
      c = Geo::Coord.new(-50.004444, 36.231389)
      c.latd.should == 50
      c.latm.should == 0
      c.lats.should be_close(16, 0.01)
      c.lath.should == 'S'
      c.latdms(true).should == [-c.latd, c.latm, c.lats]
    end

    it 'decomposes longitude to d, m, s, h' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.lngd.should == 36
      c.lngm.should == 13
      c.lngs.should be_close(53, 0.01)
      c.lngh.should == 'E'
      c.lngdms.should == [c.lngd, c.lngm, c.lngs, c.lngh]
      c.lngdms(true).should == [c.lngd, c.lngm, c.lngs]

      # Negative
      c = Geo::Coord.new(50.004444, -36.231389)
      c.lngd.should == 36
      c.lngm.should == 13
      c.lngs.should be_close(53, 0.01)
      c.lngh.should == 'W'
      c.lngdms(true).should == [-c.lngd, c.lngm, c.lngs]
    end
  end

  context 'simple conversions' do
    it 'is inspectable' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.inspect.should == '#<Geo::Coord 50.004444,36.231389>'
    end

    it 'is convertible to string' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.to_s.should == '50.004444,36.231389'

      c = Geo::Coord.new(-50.004444, -36.231389)
      c.to_s.should == '-50.004444,-36.231389'
    end

    it 'is convertible to array' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.to_a.should == [50.004444, 36.231389]
    end

    it 'is convertible to hash' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.to_h.should == {lat: 50.004444, lng: 36.231389}
      c.to_h(lat: :latitude, lng: :longitude).should ==
        {latitude: 50.004444, longitude: 36.231389}

      c.to_h(lng: :lon).should == {lat: 50.004444, lon: 36.231389}

      c.to_h(lat: 'LAT', lng: 'LNG').should ==
        {'LAT' => 50.004444, 'LNG' => 36.231389}
    end
  end

  context :strfcoord do
    it 'renders components' do
      pos = Geo::Coord.new(50.004444, 36.231389)
      neg = Geo::Coord.new(-50.004444, -36.231389)

      pos.strfcoord('%latd').should == '50'
      neg.strfcoord('%latd').should == '50'
      neg.strfcoord('%latds').should == '-50'

      pos.strfcoord('%latm').should == '0'
      pos.strfcoord('%lats').should == '16'
      pos.strfcoord('%lath').should == 'N'
      neg.strfcoord('%lath').should == 'S'

      pos.strfcoord('%lat').should == '%f' % pos.lat
      neg.strfcoord('%lat').should == '%f' % neg.lat

      pos.strfcoord('%lngd').should == '36'
      neg.strfcoord('%lngd').should == '36'
      neg.strfcoord('%lngds').should == '-36'

      pos.strfcoord('%lngm').should == '13'
      pos.strfcoord('%lngs').should == '53'
      pos.strfcoord('%lngh').should == 'E'
      neg.strfcoord('%lngh').should == 'W'

      pos.strfcoord('%lng').should == '%f' % pos.lng
      neg.strfcoord('%lng').should == '%f' % neg.lng
    end

    it 'understands flags and options' do
      pos = Geo::Coord.new(50.004444, 36.231389)
      neg = Geo::Coord.new(-50.004444, -36.231389)

      pos.strfcoord('%+latds').should == '+50'
      neg.strfcoord('%+latds').should == '-50'

      pos.strfcoord('%.02lats').should == '%.02f' % pos.lats
      pos.strfcoord('%.04lat').should == '%.04f' % pos.lat
      pos.strfcoord('%+.04lat').should == '%+.04f' % pos.lat
      pos.strfcoord('%+lat').should == '%+f' % pos.lat

      pos.strfcoord('%+lngds').should == '+36'
      neg.strfcoord('%+lngds').should == '-36'

      pos.strfcoord('%.02lngs').should == '%.02f' % pos.lngs
      pos.strfcoord('%.04lng').should == '%.04f' % pos.lng
      pos.strfcoord('%+.04lng').should == '%+.04f' % pos.lng
    end

    it 'just leaves unknown parts' do
      pos = Geo::Coord.new(50.004444, 36.231389)
      pos.strfcoord('%latd %foo').should == '50 %foo'
    end

    it 'understands everyting at once' do
      pos = Geo::Coord.new(50.004444, 36.231389)
      pos.strfcoord(%q{%latd %latm' %lats" %lath, %lngd %lngm' %lngs" %lngh}).should ==
        %q{50 0' 16" N, 36 13' 53" E}
    end
  end

  context :strpcoord do
    it 'parses components' do
      Geo::Coord.strpcoord('50.004444, 36.231389', '%lat, %lng').should ==
        Geo::Coord.new(lat: 50.004444, lng: 36.231389)

      Geo::Coord.strpcoord(
        %q{50 0' 16" N, 36 13' 53" E},
        %q{%latd %latm' %lats" %lath, %lngd %lngm' %lngs" %lngh}).should ==
        Geo::Coord.new(latd: 50, latm: 0, lats: 16, lngd: 36, lngm: 13, lngs: 53)
    end

    it 'provides defaults' do
      Geo::Coord.strpcoord('50.004444', '%lat').should ==
        Geo::Coord.new(lat: 50.004444, lng: 0)

      Geo::Coord.strpcoord('36.231389', '%lng').should ==
        Geo::Coord.new(lng: 36.231389)
    end

    it 'raises on wrong format' do
      lambda{Geo::Coord.strpcoord('50.004444, 36.231389', '%lat; %lng')}.should \
        raise_error ArgumentError, /can't be parsed/
    end

    it 'ignores the rest' do
      Geo::Coord.strpcoord('50.004444, 36.231389 is somewhere in Kharkiv', '%lat, %lng').should ==
        Geo::Coord.new(lat: 50.004444, lng: 36.231389)
    end
  end
end
