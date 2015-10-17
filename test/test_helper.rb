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


  def upload_to_project(project,file_names)
    Delayed::Worker.delay_jobs = false # turn off queuing
    dp_file = fixture_file_upload("uploads/datapackage.json", "application/json")
    @dp = project.datasources.create(datafile: File.open(dp_file), datafile_file_name: "datapackage.json")
    @dp.save
    @datapackage = JSON.parse(File.read(dp_file.tempfile.path))

    @uploads = file_names

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ds = project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @dp.id)
      ds.save
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
      ds.save

      ProcessCsvUpload.new(ds.id,@datapackage).perform

    end

  end
end
