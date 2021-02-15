# frozen_string_literal: true

RSpec.describe Geo::Coord do
  def coord(*args)
    Geo::Coord.new(*args)
  end

  describe '#initialize' do
    subject { described_class.method(:new) }

    its_call(50.004444, 36.231389) {
      is_expected.to ret have_attributes(
        lat: 50.004444,
        latitude: 50.004444,
        phi: BigDecimal('50.004444') * Math::PI / 180,
        lng: 36.231389,
        lon: 36.231389,
        longitude: 36.231389,
        la: BigDecimal('36.231389') * Math::PI / 180
      )
    }

    its_call(100, 36.231389) { is_expected.to raise_error(ArgumentError) }
    its_call(50, 360) { is_expected.to raise_error(ArgumentError) }

    its_call(lat: 50.004444, lng: 36.231389) {
      is_expected.to ret have_attributes(lat: 50.004444, lng: 36.231389)
    }

    its_call(lat: 50.004444) {
      is_expected.to ret have_attributes(lat: 50.004444, lng: 0)
    }

    its_call(lng: 36.231389) {
      is_expected.to ret have_attributes(lat: 0, lng: 36.231389)
    }

    its_call(latd: 50, lngd: 36) { is_expected.to ret coord(50, 36) }
    its_call(latd: 50, lath: 'S', lngd: 36, lngh: 'W') { is_expected.to ret coord(-50, -36) }

    its_call(latd: 50, latm: 0, lats: 16, lngd: 36, lngm: 13, lngs: 53) {
      is_expected.to ret have_attributes(lat: BigDecimal('50.00444444'), lng: BigDecimal('36.23138889'))
    }

    its_call(latd: 50, latm: 0, lats: 16) {
      is_expected.to ret have_attributes(
        lat: BigDecimal('50.00444444'),
        lng: 0
      )
    }

    its_call(lngd: 36, lngm: 13, lngs: 53) {
      is_expected.to ret have_attributes(
        lat: 0,
        lng: BigDecimal('36.23138889')
      )
    }

    its_call(lngd: 37, lngm: 30, lngs: 11.84) {
      is_expected.to ret have_attributes(
        lng: BigDecimal('37.50328889')
      )
    }

    its_call { is_expected.to raise_error(ArgumentError) }
  end

  describe '.from_h' do
    subject { described_class.method(:from_h) }

    its_call(lat: 50.004444, lng: 36.231389) { is_expected.to ret coord(50.004444, 36.231389) }

    its_call(latitude: 50.004444, longitude: 36.231389) { is_expected.to ret coord(50.004444, 36.231389) }

    its_call(lat: 50.004444, lon: 36.231389) { is_expected.to ret coord(50.004444, 36.231389) }

    its_call('lat' => 50.004444, 'lng' => 36.231389) { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('Lat' => 50.004444, 'LNG' => 36.231389) { is_expected.to ret coord(50.004444, 36.231389) }
  end

  describe '.parse_ll' do
    subject { described_class.method(:parse_ll) }

    its_call('50.004444, 36.231389') { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('50.004444,36.231389') { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('50.004444;36.231389') { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('50.004444 36.231389') { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('-50.004444 +36.231389') { is_expected.to ret coord(-50.004444, 36.231389) }
    its_call('50 36') { is_expected.to ret coord(50, 36) }

    its_call('50 36 80') { is_expected.to raise_error(ArgumentError) }
    its_call('50.04444') { is_expected.to raise_error(ArgumentError) }
  end

  describe '.parse_dms' do
    subject { described_class.method(:parse_dms) }

    its_call(%q{50 0' 16" N, 36 13' 53" E}) {
      is_expected.to ret coord(latd: 50, latm: 0, lats: 16, lath: 'N',
                               lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
    }

    its_call('50°0′16″N 36°13′53″E') {
      is_expected.to ret coord(latd: 50, latm: 0, lats: 16, lath: 'N',
                               lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
    }

    its_call('50°0’16″N 36°13′53″E') {
      is_expected.to ret coord(latd: 50, latm: 0, lats: 16, lath: 'N',
                               lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
    }

    # TODO: its_call(%{22°12'00" 33°18'00"}) { is_expected.to ret coord(latd: 22, latm: 12, lngd: 33, lngm: 18) }

    its_call('50 36 80') { is_expected.to raise_error(ArgumentError) }
  end

  describe '.parse' do
    subject { described_class.method(:parse) }

    its_call('50.004444, 36.231389') { is_expected.to ret coord(50.004444, 36.231389) }
    its_call('50 36') { is_expected.to ret coord(50, 36) }
    its_call(%q{50 0' 16" N, 36 13' 53" E}) {
      is_expected.to ret coord(latd: 50, latm: 0, lats: 16, lath: 'N',
                               lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
    }

    its_call('50') { is_expected.to ret nil }
  end

  describe '#lat*' do
    context 'when in nothern hemisphere' do
      subject(:point) { coord(50.004444, 36.231389) }

      it {
        is_expected.to have_attributes(
          latd: 50,
          latm: 0,
          lats: be_within(0.01).of(16),
          lath: 'N'
        )
      }

      describe '#latdms' do
        subject { point.method(:latdms) }

        its_call { is_expected.to ret [point.latd, point.latm, point.lats, point.lath] }
        its_call(hemisphere: false) { is_expected.to ret [point.latd, point.latm, point.lats] }
      end
    end

    context 'when in southern hemisphere' do
      subject(:point) { coord(-50.004444, 36.231389) }

      it {
        is_expected.to have_attributes(
          latd: 50,
          latm: 0,
          lats: be_within(0.01).of(16),
          lath: 'S'
        )
      }

      describe '#latdms' do
        subject { point.method(:latdms) }

        its_call { is_expected.to ret [point.latd, point.latm, point.lats, point.lath] }
        its_call(hemisphere: false) { is_expected.to ret [-point.latd, point.latm, point.lats] }
      end
    end
  end

  describe '#lng*' do
    context 'when in eastern hemisphere' do
      subject(:point) { coord(50.004444, 36.231389) }

      it {
        is_expected.to have_attributes(
          lngd: 36,
          lngm: 13,
          lngs: be_within(0.01).of(53),
          lngh: 'E'
        )
      }

      describe '#lngdms' do
        subject { point.method(:lngdms) }

        its_call { is_expected.to ret [point.lngd, point.lngm, point.lngs, point.lngh] }
        its_call(hemisphere: false) { is_expected.to ret [point.lngd, point.lngm, point.lngs] }
      end
    end

    context 'when in western hemisphere' do
      subject(:point) { coord(50.004444, -36.231389) }

      it {
        is_expected.to have_attributes(
          lngd: 36,
          lngm: 13,
          lngs: be_within(0.01).of(53),
          lngh: 'W'
        )
      }

      describe '#lngdms' do
        subject { point.method(:lngdms) }

        its_call { is_expected.to ret [point.lngd, point.lngm, point.lngs, point.lngh] }
        its_call(hemisphere: false) { is_expected.to ret [-point.lngd, point.lngm, point.lngs] }
      end
    end
  end

  describe 'simple conversions' do
    subject(:point) { coord(50.004444, 36.231389) }

    its(:inspect) { is_expected.to eq %{#<Geo::Coord 50°0'16"N 36°13'53"E>} }
    its(:latlng) { is_expected.to eq  [50.004444, 36.231389] }
    its(:lnglat) { is_expected.to eq  [36.231389, 50.004444] }

    describe '#to_s' do
      subject { point.method(:to_s) }

      its_call { is_expected.to ret %{50°0'16"N 36°13'53"E} }
      its_call(dms: false) { is_expected.to ret '50.004444,36.231389' }

      context 'when negative coordinates' do
        let(:point) { coord(-50.004444, -36.231389) }

        its_call { is_expected.to ret %{50°0'16"S 36°13'53"W} }
        its_call(dms: false) { is_expected.to ret '-50.004444,-36.231389' }
      end
    end

    describe '#to_h' do
      subject { point.method(:to_h) }

      its_call { is_expected.to ret({lat: 50.004444, lng: 36.231389}) }
      its_call(lat: :latitude, lng: :longitude) { is_expected.to ret({latitude: 50.004444, longitude: 36.231389}) }

      its_call(lng: :lon) { is_expected.to ret({lat: 50.004444, lon: 36.231389}) }

      its_call(lat: 'LAT', lng: 'LNG') { is_expected.to ret({'LAT' => 50.004444, 'LNG' => 36.231389}) }
    end
  end

  describe '#strfcoord' do
    subject { point.method(:strfcoord) }

    context 'with positive coordinates' do
      let(:point) { coord(50.004444, 36.231389) }

      its_call('%latd') { is_expected.to ret '50' }
      its_call('%latm') { is_expected.to ret '0' }
      its_call('%lats') { is_expected.to ret '16' }
      its_call('%lath') { is_expected.to ret 'N' }
      its_call('%lat') { is_expected.to ret '%f' % point.lat }

      its_call('%lngd') { is_expected.to ret '36' }
      its_call('%lngm') { is_expected.to ret '13' }
      its_call('%lngs') { is_expected.to ret '53' }
      its_call('%lngh') { is_expected.to ret 'E' }
      its_call('%lng') { is_expected.to ret '%f' % point.lng }

      its_call('%+latds') { is_expected.to ret '+50' }

      its_call('%.02lats') { is_expected.to ret '%.02f' % point.lats }
      its_call('%.04lat') { is_expected.to ret '%.04f' % point.lat }
      its_call('%+.04lat') { is_expected.to ret '%+.04f' % point.lat }
      its_call('%+lat') { is_expected.to ret '%+f' % point.lat }

      its_call('%+lngds') { is_expected.to ret '+36' }

      its_call('%.02lngs') { is_expected.to ret '%.02f' % point.lngs }
      its_call('%.04lng') { is_expected.to ret '%.04f' % point.lng }
      its_call('%+.04lng') { is_expected.to ret '%+.04f' % point.lng }

      # Just leave the unknown part
      its_call('%latd %foo') { is_expected.to ret '50 %foo' }

      # All at once
      its_call(%q{%latd %latm' %lats" %lath, %lngd %lngm' %lngs" %lngh}) {
        is_expected.to ret %q{50 0' 16" N, 36 13' 53" E}
      }
    end

    context 'with negative coordinates' do
      let(:point) { coord(-50.004444, -36.231389) }

      its_call('%latd') { is_expected.to ret '50' }
      its_call('%latds') { is_expected.to ret '-50' }

      its_call('%lath') { is_expected.to ret 'S' }

      its_call('%lat') { is_expected.to ret '%f' % point.lat }

      its_call('%lngd') { is_expected.to ret '36' }
      its_call('%lngds') { is_expected.to ret '-36' }

      its_call('%lngh') { is_expected.to ret 'W' }

      its_call('%lng') { is_expected.to ret '%f' % point.lng }

      its_call('%+latds') { is_expected.to ret '-50' }

      its_call('%+lngds') { is_expected.to ret '-36' }
    end

    context 'when carry-over required' do
      let(:point) { coord(0.033333, 91.333333) }

      its_call('%latd %latm %lats, %lngd %lngm %lngs') { is_expected.to ret '0 2 0, 91 20 0' }
      its_call('%latd %latm %.02lats, %lngd %lngm %.02lngs') { is_expected.to ret '0 2 0.00, 91 20 0.00' }
      its_call('%latd %latm %.03lats, %lngd %lngm %.03lngs') { is_expected.to ret '0 1 59.999, 91 19 59.999' }
    end
  end

  describe '#strpcoord' do
    subject { described_class.method(:strpcoord) }

    its_call('50.004444, 36.231389', '%lat, %lng') {
      is_expected.to ret coord(lat: 50.004444, lng: 36.231389)
    }

    its_call(
      %q{50 0' 16" N, 36 13' 53" E},
      %q{%latd %latm' %lats" %lath, %lngd %lngm' %lngs" %lngh}
    ) { is_expected.to ret coord(latd: 50, latm: 0, lats: 16, lngd: 36, lngm: 13, lngs: 53) }

    its_call('50.004444', '%lat') { is_expected.to ret coord(lat: 50.004444, lng: 0) }

    its_call('36.231389', '%lng') { is_expected.to ret coord(lng: 36.231389) }

    its_call('50.004444, 36.231389', '%lat; %lng') {
      is_expected.to raise_error ArgumentError, /can't be parsed/
    }

    its_call('50.004444, 36.231389 is somewhere in Kharkiv', '%lat, %lng') {
      is_expected.to ret coord(lat: 50.004444, lng: 36.231389)
    }
  end
end
