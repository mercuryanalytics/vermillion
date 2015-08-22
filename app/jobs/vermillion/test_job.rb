module Vermillion
  class TestJob < ActiveJob::Base
    def perform(*args)
    end

    def self.description_schema
      {
        # "$schema" => "http://json-schema.org/schema#",
        "id" => "http://mercuryanalytics.com/schemas/vermillion/test.json",
        "title" => "Test job schema",
        "type" => "object",
        "required" => ["url"],
        "properties" => {
          "url" => { "type" => "string" }
        }
      }
    end
  end
end
