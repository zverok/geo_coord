# Geo::Coord changelog

## 0.2.0 - Feb 15, 2021

* Support Ruby versions up to 3.0
* Drop compatibility checks for Ruby < 2.4
* Update specs to modern style (no hope to make it to standard library after 5 years :shrug:)
* Fix seconds fraction truncation in DMS-initialization (@matthew-angelswing)
* Change positional `hemisphere` argument in `to_s` to keyword for clarity

## 0.1.0 - Feb 3, 2018

* Switch to `BigDecimal` for internal values storage;
* More friendly `#inspect` & `#to_s` format;
* Rename `#to_a` to `#latlng` & `#lnglat`;
* Fix `#lats` formula bug.

## 0.0.1 - Jun 06, 2016

Initial release as a gem.
