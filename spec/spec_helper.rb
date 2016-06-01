if Object.const_defined?(:RSpec) # otherwise it is mspec
  require 'stringio'
  require 'simplecov'
  require 'coveralls'

  Coveralls.wear!

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter]
  )

  SimpleCov.start

  RSpec.configure do |c|
    c.deprecation_stream = StringIO.new # just make it silent
  end
end

TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)

$:.unshift 'lib'
require 'geo/coord'
