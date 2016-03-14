$:.unshift 'lib'
require 'geo/coord'
require 'geo/globes'

TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)
