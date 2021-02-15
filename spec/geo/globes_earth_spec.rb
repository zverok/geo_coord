# frozen_string_literal: true

RSpec.describe Geo::Coord::Globes::Earth do
  def coord(*args)
    Geo::Coord.new(*args)
  end

  let(:washington_dc) { coord(38.898748, -77.037684) }
  let(:chicago) { coord(41.85, -87.65) }
  let(:anti_washington) { coord(-38.898748, 102.962316) }

  it 'calculates distance (by Vincenty formula)' do # rubocop:disable RSpec/MultipleExpectations
    expect(washington_dc.distance(washington_dc)).to eq 0
    expect(washington_dc.distance(chicago)).to be_within(1).of(chicago.distance(washington_dc))
    expect(washington_dc.distance(chicago)).to be_within(1).of(958_183)

    # vincenty by design fails on antipodal points
    expect(washington_dc.distance(anti_washington)).to be_within(1).of(20_037_502)
  end

  describe '#azimuth' do
    subject { ->((lat1, lng1), (lat2, lng2)) { coord(lat1, lng1).azimuth(coord(lat2, lng2)) } }

    # same point
    its_call([38.898748, -77.037684], [38.898748, -77.037684]) { is_expected.to ret 0 }

    # straight angles:
    its_call([41, -75], [39, -75]) { is_expected.to ret be_within(1).of(180) }
    its_call([40, -74], [40, -76]) { is_expected.to ret be_within(1).of(270) }
    its_call([39, -75], [41, -75]) { is_expected.to ret be_within(1).of(0) }
    its_call([40, -76], [40, -74]) { is_expected.to ret be_within(1).of(90) }

    # some direction on map
    its_call([38.898748, -77.037684], [41.85, -87.65]) { is_expected.to ret be_within(1).of(293) }

    # vincenty by design fails on antipodal points
    its_call([38.898748, -77.037684], [-38.898748, 102.962316]) { is_expected.to ret be_within(1).of(90) }
  end

  it 'calculates endpoint' do
    d = washington_dc.distance(chicago)
    a = washington_dc.azimuth(chicago)

    endpoint = washington_dc.endpoint(d, a)
    endpoint.should == chicago
  end
end
