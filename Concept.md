## Proposal

Add `Geo::Coord` class to Ruby standard library, representing
`[latitude, longitude]` pair + convenience methods. Add `Geo` standard
library with additional calculations and convenience methods.

## Rationale

In modern applications, working with geographical coordinates is frequent.
We propose to think of such coordinates (namely, `latitude, longitude` pair)
as of "basic" type that should be supported by standard library - the same
way as we support `Time`/`Date`/`DateTime` instead of having it defined
by user/gems.

This type is too "small" to be defined by separate gem, so, all of existing
geo gems (GeoKit, RGeo, GeoRuby, Graticule etc.) define their own
`LatLng`, or `Location`, or `Point`, whatever.

On other hand, API design for this "small" type is vague enough for all
those similar types to be incompatible and break small habits and conventions
when you change from one geo library to another, or try to use several
simultaneously.

Additionaly, many gems somehow working with geo coordinates (for weather,
or timezone, or another tasks) generally prefer not to introduce type, and
just work with `[lat, lng]` array, which is not very convenient, faithfully.

So, having "geo coordinates" functionality in standard library seems
reasonable and valuable.

## Existing/reference solutions

Ruby:

* [GeoKit::LatLng](http://www.rubydoc.info/github/geokit/geokit/master/Geokit/LatLng);
* [RGeo::Feature::Point](http://www.rubydoc.info/gems/rgeo/RGeo/Feature/Point)
  (with several "private" implementation classes); RGeo implements full
  [OGC Simple Features](https://en.wikipedia.org/wiki/Simple_Features) specification,
  so, its points have `z` and `m` coordinates, projection and much more;
* [Graticule::Location](http://www.rubydoc.info/github/collectiveidea/graticule/Graticule/Location)
  (not strictly a `[lat,lng]` wrapper);
* [Rosamary::Node](http://www.rubydoc.info/gems/rosemary/0.4.4/Rosemary/Node)
  (follows naming convention of underlying OpenStreetMap API);

Other sources:
* Python: [geopy.Point](http://geopy.readthedocs.org/en/latest/#geopy.point.Point);
* [ElasticSearch](https://www.elastic.co/blog/geo-location-and-search)
  uses hash with "lat" and "lon" keys;
* Google Maps [Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro#GeocodingResponses)
  uses hash with "lat" and "lng" keys;
* PostGIS: [pretty complicated](http://postgis.net/docs/manual-2.2/using_postgis_dbmanagement.html#RefObject)
  has _geometrical_ (projected) and _geographical_ (lat, lng) points and
  stuff.

## Design decisions

While designing `Geo` library, our reference point was standard `Time`
class (and, to lesser extent, `Date`/`DateTime`). It has this
responsibilities:
* stores data in simple internal form;
* helps to parse and format data to and from strings;
* provides easy access to logical components of time;
* allows most simple and unambiguous calculations.

**Main type name**: as far as I can see, there's no good singular name
for `(lat, lng)` pair concept. As mentioned above, there can be seen
names like `LatLng`, or `Location`, or `Point`; and in natural language
just "coordinates" used frequently. We propose the name `Coord`, which
is pretty short, easy to remember, demonstrates intentions (and looks
like singular, so you can have "one coord object" and "array of coords",
which is not 100% linguistically correct, yet convenient). Alternative
`Point` name seems to be too ambigous, being used in many contexts.

`Geo::Coord` object is **immutable**, there's no semantical sense in
`location.latitude = ...` or something like this.

**Units**: `Geo` calculations (just like `Time` calculations) provide
no units options, just returning numbers measured in SI units: metres
for distances and radians for directions (not for latitude/longitude
themselves, they are degrees).

**Order relation** is defined on `Geo::Coord` through comparison of their
_geohashes_. Coordinates comparison has no clear "physical meaning" (as
you can't say what it means of "point A" is "less than point B"), but
comparability is important for value objects, and _sorting_ array of
points by geohash provides near-to-intuitive results: points that are
adjacent in sorted array, are nearest to each other on the map. (This
intuition is broken on quadrant edges, which should be stated clearly
in documentation.)

There's introduced **concept of globe** for calculations. Only generic
(sphere) and Earth globes are implemented, but for 2016 we feel like
current design of basic types should take in consideration possibility
of writing Ruby scripts for Mars maps analysis.

No **map projection** math was added into current proposal, but it
may be a good direction for further work. No **elevation** data considered
either.

## Proposal details

### `Geo::Coord` class

Represents `[latitude, longitude]` pair. Latitude is -90 to +90 (degrees).
Longitude is -180 to +180.

Class methods:
* `new(lat, lng)` creates instance from two Numerics (in degrees);
* `new(lat:, lng:)` keyword arguments form of above;
* `new(latd:, latm:, lats:, lath:, lngd: lngm:, lngs: lngh:)` creates
  instance from coordinates in (deg, min, sec, hemisphere) form; hemispheres
  are "N"/"S" for latitude and "W"/E" for longitude; any component except
  for degrees can be omitted; if hemisphere is omitted, it is decided by
  degrees sign (lat: positive is "N", lng: positive is "E");
* `from_h(hash)` creates instance from hash with `"lat"` or `"latitude"`
  key and `"lon"` or `"lng"` or `"longitude"` key (case-independent);
* `strpcoord` parses string into coordinates by provided pattern (see
  below for pattern description);
* `parse_ll` parses coordinates string in `"float, float"` form;
* `parse_dms` parses coordinates string in `d m s h, d m s h` format
  (considering several widely used symbols for degrees, minutes and seconds);
* `geohash(str)` parses coordinates from [Geohash](https://en.wikipedia.org/wiki/Geohash);
* `parse` tries to parse string into coordinates from various formats.

Instance methods:
* `lat` and `lng`, returning `Float`s, signed;
* `latitude` and `longitude` as an aliases; `lon` as an additional
  aliase for longitude;
* `latd`, `latm`, `lats`, `lath`: degree, minute, second, hemisphere;
  `latd` and `latm` are `Fixnum`, `lats` is `Float`, `lath` is "N"/"S"; all
  numbers are unsigned;
* `lngd`, `lngm`, `lngs`, `lngh`: the same for longitude (hemisphere is
  "W"/"E");
* `latdms(nohemisphere = false)` returns `[latd, latm, lats, lath]` with
  `hemisphere` param equal to `true`, and `[±latd, latm, lats]` with
  `false`; same with `lngdms` for longitude;
* `to_s` returning string like "50.004444,36.231389" (good for map
  URLs construction, for example);
* `to_h(lat: :lat, lng: :lng)` converts coord to hash (with
  desired key names);
* `to_a` converts coord to simple `[lat, lng]` pair;
* `geohash(precision)`, returning [Geohash](https://en.wikipedia.org/wiki/Geohash)
  from coordinates;
* `strfcoord(formatstr)` for complex coordinate formatting (see below
  for format string description);
* several geodesy math routines (distances and directions) are included
  from `Geo::Globes::Earth`.

#### `strpcoord`/`strfcoord`

Example:
```ruby
kharkiv.strfcoord('%latdu°%latm′%lats″ %lath, %lngdu°%lngm′%lngs″ %lngh')
# => "50°0′16″ N, 36°13′53″ E"
```

Directives:
* `%lat` - full latitude, float; can be formatted with more control like
  `%.4lat` (four digits after point) or `%+lat` (explicit plus sign for
  positive latitudes);
* `%latd` - latitude degrees, unsigned, integer
* `%latds` - latitude degrees, signed
* `%latm` - latitude minutes, unsigned, integer
* `%lats` - latitude seconds, unsigned, integer, but can be formatted as
  float: `%.2lats`
* `%lath` - latitude hemisphere, one letter ("N"/"S")
* `%lng`, `%lngd`, `%lngds`, `%lngs`, `%lngh`, `%lngH` - same for longitude
* `%%` literal `%` sign

### `Geo::Globes` module

Each _globe_ corresponds to some planet, and is a module containing math
for this planet. Currently, only `Geo::Globes::Generic` and `Geo::Globes::Earth`
are defined.

#### `Geo::Globes::Generic`

Module expects to be included into `Geo::Coord`

Module constants:
* `DISTANCE_FORMULAE = [:haversine, :flat]`

Module methods:
* `direction(to)`, also aliased as `azimuth(to)`, returned in radians;
* `flat_distance(to)` - pythagorean distance between self and `to`;
* `haversine_distance(to)` - spherical distance;
* `distance(to, formula = DISTANCE_FORMULAE.first)` - default distance
  calculation;

#### `Geo::Globes::Earth`

Includes `Generic` and extends it with (now default) `vincent_distance`
method.

Included into `Geo::Coord` by default.
