require File.expand_path('../../spec_helper', __FILE__)

describe Geo::Coord do
  context :initialize do
    it 'is initialized by (lat, lng)' do
      c = Geo::Coord.new(50.004444, 36.231389)
      c.lat.should == 50.004444
      c.latitude.should == 50.004444

      c.lng.should == 36.231389
      c.lon.should == 36.231389
      c.longitude.should == 36.231389
    end

    it "controls argument ranges" do
      lambda{Geo::Coord.new(100, 36.231389)}.should raise_error(ArgumentError)

      lambda{Geo::Coord.new(50, 360)}.should raise_error(ArgumentError)
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
end
