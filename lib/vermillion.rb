require "sprockets/railtie"
require "coffee-rails"
require "slim-rails"
require "jbuilder"
require "json-schema"

JSON::Validator.use_multi_json = false

require "vermillion/engine"

module Vermillion
end
