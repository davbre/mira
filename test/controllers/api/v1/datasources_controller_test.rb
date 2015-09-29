require 'test_helper'
# require_relative '../../app/controllers/api/v1/projects_controller'
# require 'minitest/spec'

class Api::V1::DatasourcesControllerTest < ActionController::TestCase

  include Devise::TestHelpers


  setup do
    sign_in users(:one)    
    # @project = projects(:one)
    @user = users(:one)

    Delayed::Worker.delay_jobs = false # turn off queuing

    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save

    dp_file = fixture_file_upload("uploads/datapackage.json", "application/json")
    @dp = @project.datasources.create(datafile: File.open(dp_file), datafile_file_name: "datapackage.json")
    @dp.save
    datapackage = JSON.parse(File.read(dp_file.tempfile.path))

    @uploads = ["upload1", "upload2"]

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ds = @project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @dp.id) 
      ds.save
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
      ds.save

      ProcessCsvUpload.new(ds.id,datapackage).perform

    end
  end


  test "API's projects/[id]/tables endpoint response ok" do
    get :index, :id => @project.id
    assert_response :success
  end  

  test "API's projects/[id]/tables endpoint response contains all uploads" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @uploads.length
  end  

  test "API's projects/[id]/tables endpoint response contains all uploads" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @uploads.length
  end  

end
