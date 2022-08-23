module Vermillion
  class Engine < ::Rails::Engine
    isolate_namespace Vermillion

    initializer "Vermillion.assets.precompile" do |app|
      app.config.assets.precompile += %w( application.js )
    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
