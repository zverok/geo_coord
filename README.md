# Geo::Coord—simple geo coordinates class for Ruby

[![Gem Version](https://badge.fury.io/rb/geo_coord.svg)](http://badge.fury.io/rb/geo_coord)
[![Dependency Status](https://gemnasium.com/zverok/geo_coord.svg)](https://gemnasium.com/zverok/geo_coord)
[![Build Status](https://travis-ci.org/zverok/geo_coord.svg?branch=master)](https://travis-ci.org/zverok/geo_coord)
[![Coverage Status](https://coveralls.io/repos/zverok/geo_coord/badge.svg?branch=master)](https://coveralls.io/r/zverok/geo_coord?branch=master)

`Geo::Coord` is a basic class representing `[latitude, longitude]` pair
and incapsulating related concepts and calculations.

## Features

* Simple storage for geographical latitude & longitude pair;
* Easily converted from/to many different representations (arrays, hashes,
  degrees/minutes/seconds, radians, strings with different formatting);
* Geodesy math (distances, directions, endpoints) via precise Vincenty
  formula.

## Reasons

Geo coordinates are, in fact, one of basic types in XXI century programming.

This gem is a (desperate) attempt to provide such a "basic" type ready
to be dropped into any of Ruby code, to unify all different `LatLng` or
`Point` or `Location` classes in existing geography and geo-aware gems
for easy data exchange and natural usage.

As an independent gem, this attempt is doomed by design, but why not
to try?..

Initially, I've done this work as a proposal for inclusion in Ruby's
standard library, but it was not met very well.
So, now I'm releasing it as a gem to be available at least for my own
other projects.

You can read my initial proposal [here](https://github.com/zverok/geo_coord/blob/master/StdlibProposal.md)
and discussion in Ruby tracker [there](https://bugs.ruby-lang.org/issues/12361).

I still have a small hope it would be part of stdlib once, that's why I
preserve the style of specs (outdated rspec, but compatible with mspec used
for standard library) and docs (yard in RDoc-compatibility mode).

## Design decisions

While designing `Geo` library, my reference point was standard `Time`
class (and, to lesser extent, `Date`/`DateTime`). It has these
responsibilities:
* stores data in simple internal form;
* helps to parse and format data to and from strings;
* provides easy access to logical components of data;
* allows most simple and unambiguous calculations.

**Namespace name**: The gem takes pretty short and generic top-level
namespace name `Geo`, but creates only one class inside it: `Geo::Coord`.

**Main type name**: as far as I can see, there's no good singular name
for `(lat, lng)` pair concept. In different libraries, there can be seen
names like `LatLng`, or `Location`, or `Point`; and in natural language
just "coordinates" used frequently. I propose the name `Coord`, which
is pretty short, easy to remember, demonstrates intentions (and looks
like singular, so you can have "one coord object" and "array of coords",
which is not 100% linguistically correct, yet convenient). Alternative
`Point` name seems to be too ambiguous, being used in many contexts.

`Geo::Coord` object is **immutable**, there's no semantical sense in
`location.latitude = ...` or something like this.

**Units**: `Geo` calculations (just like `Time` calculations) provide
no units options, just returning numbers measured in "default" units:
metres for distances (as they are SI unit) and degrees for azimuth.
Latitude and longitude are stored in degrees, but radians values accessors
are provided (being widely used in geodesy math).

All coordinates and calculations are thought to be in
[WGS 84](https://en.wikipedia.org/wiki/World_Geodetic_System#A_new_World_Geodetic_System:_WGS_84)
coordinates reference system, being current standard for maps and GPS.

There's introduced **a concept of globe** used internally for calculations.
Only generic (sphere) and Earth globes are implemented, but for 2016 I
feel like the current design of basic types should take in consideration
possibility of writing Ruby scripts for Mars maps analysis. Only one
geodesy formula is implemented (Vincenty, generally considered one of
the most precise), as for standard library class it considered
unnecessary to provide a user with geodesy formulae options.

No **map projection** math was added into the current gem, but it
may be a good direction for further work. No **elevation** data considered
either.

## Installation

Now when it is a gem, just do your usual `gem install geo_coord` or add
`gem "geo_coord", require: "geo/coord"` to your Gemfile.

## Usage

### Creation

```ruby
# From lat/lng pair:
g = Geo::Coord.new(50.004444, 36.231389)
# => #<Geo::Coord 50.004444,36.231389>

# Or using keyword arguments form:
g = Geo::Coord.new(lat: 50.004444, lng: 36.231389)
# => #<Geo::Coord 50.004444,36.231389>

# Keyword arguments also allow creation of Coord from components:
g = Geo::Coord.new(latd: 50, latm: 0, lats: 16, lath: 'N', lngd: 36, lngm: 13, lngs: 53, lngh: 'E')
# => #<Geo::Coord 50.004444,36.231389>
```

For parsing API responses you'd like to use `from_h`,
which accepts String and Symbol keys, any letter case,
and knows synonyms (lng/lon/longitude):

```ruby
g = Geo::Coord.from_h('LAT' => 50.004444, 'LON' => 36.231389)
# => #<Geo::Coord 50.004444,36.231389>
```

For math, you'd probably like to be able to initialize
Coord with radians rather than degrees:

```ruby
g = Geo::Coord.from_rad(0.8727421884291233, 0.6323570306208558)
# => #<Geo::Coord 50.004444,36.231389>
```

There's also family of string parsing methods, with different
applicability:

```ruby
# Tries to parse (lat, lng) pair:
g = Geo::Coord.parse_ll('50.004444, 36.231389')
# => #<Geo::Coord 50.004444,36.231389>

# Tries to parse degrees/minutes/seconds:
g = Geo::Coord.parse_dms('50° 0′ 16″ N, 36° 13′ 53″ E')
# => #<Geo::Coord 50.004444,36.231389>

# Tries to do best guess:
g = Geo::Coord.parse('50.004444, 36.231389')
# => #<Geo::Coord 50.004444,36.231389>
g = Geo::Coord.parse('50° 0′ 16″ N, 36° 13′ 53″ E')
# => #<Geo::Coord 50.004444,36.231389>

# Allows user to provide pattern:
g = Geo::Coord.strpcoord('50.004444, 36.231389', '%lat, %lng')
# => #<Geo::Coord 50.004444,36.231389>
```

[Pattern language description](http://www.rubydoc.info/gems/geo_coord/Geo/Coord#strpcoord-class_method)

### Examining the object

Having Coord object, you can get its properties:

```ruby
g = Geo::Coord.new(50.004444, 36.231389)
g.lat # => 50.004444
g.latd # => 50 -- latitude degrees
g.lath # => N -- latitude hemisphere
g.lngh # => E -- longitude hemishpere
g.phi  # => 0.8727421884291233 -- longitude in radians
g.latdms # => [50, 0, 15.998400000011316, "N"]
# ...and so on
```

### Formatting and converting

```ruby
g.to_s # => "50.004444,36.231389"
g.strfcoord('%latd°%latm′%lats″%lath %lngd°%lngm′%lngs″%lngh')
# => "50°0′16″N 36°13′53″E"

g.to_h(lat: 'LAT', lng: 'LON') # => {'LAT'=>50.004444, 'LON'=>36.231389}
```

### Geodesy math

```ruby
kharkiv = Geo::Coord.new(50.004444, 36.231389)
kyiv = Geo::Coord.new(50.45, 30.523333)

kharkiv.distance(kyiv) # => 410211.22377421556
kharkiv.azimuth(kyiv) # => 279.12614358262067
kharkiv.endpoint(410_211, 280) # => #<Geo::Coord 50.505975,30.531283>
```

[Full API Docs](http://www.rubydoc.info/gems/geo_coord)

## Author

[Victor Shepelev](https://zverok.github.io)

## License

[MIT](https://github.com/zverok/geo_coord/blob/master/LICENSE.txt).
