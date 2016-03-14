require File.expand_path('../../spec_helper', __FILE__)

describe Geo::Globes::Earth do
  before{
    @globe = Geo::Globes::Earth.instance

    @washington_dc = Geo::Coord.new(38.898748, -77.037684)
    @chicago = Geo::Coord.new(41.85, -87.65)
    @anti_washington = Geo::Coord.new(-38.898748, 102.962316)
  }

  it 'calculates spheric distance' do
    @globe.spheric_distance(@washington_dc, @washington_dc).should == 0
    @globe.spheric_distance(@washington_dc, @chicago).should be_close(957275, 1)
    @globe.spheric_distance(@washington_dc, @chicago).should ==
      @globe.spheric_distance(@chicago, @washington_dc)
  end

  it 'calculates haversine distance' do
    @globe.haversine_distance(@washington_dc, @washington_dc).should == 0
    @globe.haversine_distance(@washington_dc, @chicago).should be_close(957275, 1)
    @globe.haversine_distance(@washington_dc, @chicago).should ==
      @globe.haversine_distance(@chicago, @washington_dc)
  end

  it 'calculates Vincenty distance' do
    @globe.vincenty_distance(@washington_dc, @washington_dc).should == 0
    @globe.vincenty_distance(@washington_dc, @chicago).should \
      be_close(@globe.vincenty_distance(@chicago, @washington_dc), 1)
    @globe.vincenty_distance(@washington_dc, @chicago).should be_close(958183, 1)

    # vincenty by design fails on antipodal points
    @globe.vincenty_distance(@washington_dc, @anti_washington).should ==
      @globe.haversine_distance(@washington_dc, @anti_washington)
  end

  #it 'calculates direction' do
  #end

  #it 'calculates endpoint' do
  #end
end
