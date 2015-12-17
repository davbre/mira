require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mira
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true


    ###########################################################
    ###########################################################

    # DBR: as per https://github.com/collectiveidea/delayed_job
    config.active_job.queue_adapter = :delayed_job
    config.x.db_table_prefix = 'Xy'

    # DBR: paging max
    config.x.api_default_per_page = 25;
    config.x.api_max_per_page = 200;

    # DBR: job logs
    config.x.job_log_path = "#{Rails.root}/public/job_logs"

    config.x.upload_path = "#{Rails.root}/public/uploads"

    # This is not exactly required but decided to make it explicit
    # as we can see below that we are :expose'ing some of these
    # headers in the rack-cors section
    ApiPagination.configure do |config|
      config.paginator = :kaminari # or :will_paginate
      config.total_header = 'Records-Total'
      config.per_page_header = 'Records-Per-Page'
    end

    # DBR: see https://devmynd.com/blog/2014-7-rails-ember-js-with-the-ember-cli-redux-part-1-the-api-and-cms-with-ruby-on-rails
    #          http://www.adobe.com/devnet/archive/html5/articles/understanding-cross-origin-resource-sharing-cors.html
#"Rack::Cors"
    config.middleware.insert_before "ActionDispatch::Static", "Rack::Cors", :debug => true, :logger => (-> { Rails.logger }) do
      allow do
        origins '*'
        resource '*',
        :headers => :any,
        :expose => ['Records-Total','Records-Per-Page'], # the total which will be used for pagination
        #:expose => ['X-User-Authentication-Token', 'X-User-Id'],
        :methods => [:get, :post, :options, :patch, :delete]
      end
    end


    config.gzip_compression = true

    # DBR: want to save datapackage.json. Ran into issue where saving the file was causing
    # validation errors ("has contents that are not what they are reported to be"). Came across
    # this same issue and solution:
    # https://github.com/thoughtbot/paperclip/issues/1477#issuecomment-66522989
    Paperclip.options[:content_type_mappings] = {
      :json => "text/plain"
    }
  end
end
