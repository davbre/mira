ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def log_dir
    Rails.configuration.x.job_log_path
  end

  def upload_dir
    Rails.configuration.x.upload_path
  end

  def map_datapackage_column_types(datapackage, csv_name)
    csv_dp_detail = datapackage["resources"].detect{ |a| a["path"] == csv_name }
    dp_column_types = {}
    csv_dp_detail["schema"]["fields"].each do |sf|
      dp_column_types[sf["name"]] = LoadTable.type_map[sf["type"]]
    end
    dp_column_types
  end

  def default_page_size
    Rails.application.config.x.api_default_per_page
  end
end
