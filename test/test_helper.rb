ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include ApplicationHelper
  include ProjectHelper

  # Add more helper methods to be used by all tests here...

  # def map_datapackage_column_types(datapackage, csv_name)
  #   csv_dp_detail = datapackage["resources"].detect{ |a| a["path"] == csv_name }
  #   dp_column_types = {}
  #   csv_dp_detail["schema"]["fields"].each do |sf|
  #     dp_column_types[sf["name"]] = LoadTable.type_map[sf["type"]]
  #   end
  #   dp_column_types
  # end

  def default_page_size
    Rails.application.config.x.api_default_per_page
  end


  def upload_to_project(project,file_names,datapackage_file = "uploads/datapackage.json")
    Delayed::Worker.delay_jobs = false # turn off queuing
    @dp_file = fixture_file_upload(datapackage_file, "application/json")
    @datapackage = Datapackage.new(project_id: project.id,
                                   datapackage: File.open(@dp_file.path),
                                   datapackage_file_name: "datapackage.json")
    # project.datapackage.create(datapackage: File.open(dp_file), datapackage_file_name: "datapackage.json")
    # @dp = project.datasources.create(datafile: File.open(dp_file), datafile_file_name: "datapackage.json")
    @datapackage.save
    # mimic what happens in controller
    @feedback = { errors: [], warnings: [], notes: []}
    json_dp = check_and_clean_datapackage(@dp_file)
    save_datapackage(@datapackage)
    extract_and_save_datapackage_resources(@datapackage,json_dp)

    @uploads = file_names

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ds = project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @datapackage.id)
      ds.save
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
      ds.save
      ProcessCsvUpload.new(ds.id).perform

    end

  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end
