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
    @globe.vincenty_distance(@washington_dc, @chicago).should be_close(958183, 1)

    # vincenty by design fails on antipodal points
    @globe.distance(@washington_dc, @anti_washington).should ==
      @globe.send(:haversine_distance, @washington_dc, @anti_washington)
  end

  it 'calculates azimuth' do
  end

  #it 'calculates endpoint' do
  #end
end
