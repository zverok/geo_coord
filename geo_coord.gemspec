require './lib/geo/coord/version'

Gem::Specification.new do |s|
  s.name     = 'geo_coord'
  s.version  = Geo::Coord::VERSION
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/geo_coord'

  s.summary = 'Geo::Coord class'
  s.description = <<-DESC
  DESC
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ %r{^(?: spec\/.* |Gemfile |Rakefile
    |\.rspec |\.gitignore |\.rubocop.yml
    |\.travis.yml
    )$}x
  end
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.4.0'

  s.add_development_dependency 'rubocop', '>= 0.40'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'dokaz'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'saharspec'
end
