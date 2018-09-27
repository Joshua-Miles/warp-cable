$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "warp/cable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "warp-cable"
  s.version     = Warp::Cable::VERSION
  s.authors     = ["joshua-miles"]
  s.email       = [""]
  s.homepage    = "http://google.com"
  s.summary     = "Utility for building realtime apps with rails"
  s.description = "Utility for building realtime apps with rails"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"

  s.add_development_dependency "sqlite3"
end
