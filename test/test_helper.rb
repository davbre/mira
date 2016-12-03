ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'net/http'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include ApplicationHelper
  include ProjectHelper
  include DataAccessHelper
  # Add more helper methods to be used by all tests here...

  def map_datapackage_column_types(datapackage_json, csv_name)
    csv_dp_detail = datapackage_json["resources"].detect{ |a| a["path"] == csv_name }
    dp_column_types = {}
    csv_dp_detail["schema"]["fields"].each do |sf|
      dp_column_types[sf["name"]] = DATAPACKAGE_TYPE_MAP[sf["type"]]
    end
    dp_column_types
  end

  def default_page_size
    Rails.application.config.x.api_default_per_page
  end


  def upload_to_project(controller,project,file_names,datapackage_file = "uploads/datapackage.json")
    Delayed::Worker.delay_jobs = false # turn off queuing
    @dp_file = fixture_file_upload(datapackage_file, "application/json")

    # The call to the "post" method would fail when called outside the context of a ProjectsController
    # so we change it temporarily. This allows us to upload the datapackage from tests not relating directly
    # to project actions. See http://stackoverflow.com/a/7743176/1002140
    orig_controller = controller
    @controller = ProjectsController.new
    post :upload_datapackage, id: project.id, :datapackage => @dp_file
    @controller = orig_controller

    @uploads = file_names
    @datapackage = Datapackage.last

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      # need the datapackage_resource_id to mimic what's going on in the controller.
      dpr_name = map_csv_basename(@datapackage, upl)
      dpr = DatapackageResource.where(datapackage_id: @datapackage.id, table_ref: dpr_name).first
      ds = project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @datapackage.id, datapackage_resource_id: dpr.id)
      ds.save
      Delayed::Job.enqueue ProcessCsvUpload.new(ds.id,"quick")
    end
  end

  def csv_line_count(txtfile)
    csv_file = fixture_file_upload("uploads/" + txtfile + ".csv", "text/plain")
    row_count = File.open(csv_file,"r").readlines.size
    row_count
  end

end

class ActionController::TestCase
  include Devise::TestHelpers
end
