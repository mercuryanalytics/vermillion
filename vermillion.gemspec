$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vermillion/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vermillion"
  s.version     = Vermillion::VERSION
  s.authors     = ["Scott Brickner"]
  s.email       = ["scottb@mercuryanalytics.com"]
  s.homepage    = "http://mercuryanalytics.com/"
  s.summary     = "Summary of Vermillion."
  s.description = "Description of Vermillion."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.2.3"
  s.add_dependency "coffee-rails"
  s.add_dependency "coffee-rails-source-maps"
  s.add_dependency "sass-rails"
  s.add_dependency "slim-rails"
  s.add_dependency "jbuilder"
  s.add_dependency "json-schema"

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "pry-rails"
end
