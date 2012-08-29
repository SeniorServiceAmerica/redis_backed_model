# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis_backed_model/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ian Whitney", "Davin Lagerroos"]
  gem.email         = ["iwhitney@ssa-i.org","dlaerroos@ssa-i.org"]
  gem.description   = %q{Provides methods to models that are backed by a redis instance.}
  gem.summary       = %q{Provides methods for the creation of redis-backed models, specifically the handling of sorted-set attributes and returning commands that will store the object in redis.}
  gem.homepage      = "https://github.com/SeniorServiceAmerica/redis_backed_model"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "redis_backed_model"
  gem.require_paths = ["lib"]
  gem.version       = RedisBackedModel::VERSION
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'redis'
  gem.add_dependency('activesupport')
end
