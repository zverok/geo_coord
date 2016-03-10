$:.unshift 'lib'
require 'geo/coord'

TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)
