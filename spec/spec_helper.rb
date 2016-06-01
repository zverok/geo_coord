$:.unshift 'lib'
require 'geo/coord'

TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)

if Object.const_defined?(:RSpec)
  require 'stringio'

  RSpec.configure do |c|
    c.deprecation_stream = StringIO.new # just make it silent
  end
end
