require File.expand_path('../../spec_helper', __FILE__)

describe Geo::Globes::Earth do
  before{
    @globe = Geo::Globes::Earth.instance

    @washington_dc = Geo::Coord.new(38.898748, -77.037684)
    @chicago = Geo::Coord.new(41.85, -87.65)
    @anti_washington = Geo::Coord.new(-38.898748, 102.962316)
  }

  it 'calculates distance (by Vincenty formula)' do
    @globe.distance(@washington_dc, @washington_dc).should == 0
    @globe.distance(@washington_dc, @chicago).should \
      be_close(@globe.distance(@chicago, @washington_dc), 1)
    @globe.distance(@washington_dc, @chicago).should be_close(958183, 1)

    # vincenty by design fails on antipodal points
    @globe.distance(@washington_dc, @anti_washington).should be_close(20037502, 1)
  end

  it 'calculates azimuth' do
    # same point
    @globe.azimuth(@washington_dc, @washington_dc).should == 0

    # straight angles:
    @globe.azimuth(Geo::Coord.new(41, -75), Geo::Coord.new(39, -75)).should \
      be_close(180, 1)

    @globe.azimuth(Geo::Coord.new(40, -74), Geo::Coord.new(40, -76)).should \
      be_close(270, 1)

    @globe.azimuth(Geo::Coord.new(39, -75), Geo::Coord.new(41, -75)).should \
      be_close(0, 1)

    @globe.azimuth(Geo::Coord.new(40, -76), Geo::Coord.new(40, -74)).should \
      be_close(90, 1)
    
    # some direction on map
    @globe.azimuth(@washington_dc, @chicago).should be_close(293, 1)

    # vincenty by design fails on antipodal points
    @globe.azimuth(@washington_dc, @anti_washington).should be_close(90, 1)
  end

  it 'calculates endpoint' do
    d = @globe.distance(@washington_dc, @chicago)
    a = @globe.azimuth(@washington_dc, @chicago)

    endpoint = @globe.endpoint(@washington_dc, d, a)
    endpoint.lat.should be_close(@chicago.lat, 0.1)
    endpoint.lng.should be_close(@chicago.lng, 0.1)
  end
end
