require 'test_helper'
# require_relative '../../app/controllers/api/v1/projects_controller'
# require 'minitest/spec'

class Api::V1::DatasourcesEndpointsTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    Delayed::Worker.delay_jobs = false # turn off queuing
    sign_in users(:one)
    @controller = Api::V1::DatasourcesController.new # See http://stackoverflow.com/a/7743176
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @uploads = ["upload1","upload2"]

    upload_to_project(@controller,@project, @uploads, "uploads/datapackage/good/datapackage.json") # just upload datapackage file

    @dp_file_json = JSON.parse(File.read(@dp_file))
  end

  # api/project/:id/tables
  test "Enpoint api/projects/:id/uploads - response ok" do
    get :index, :id => @project.id
    assert_response :success
  end

  test "Endpoint api/projects/:id/uploads - response contains same number of uploads" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @uploads.length
  end

  test "Endpoint api/projects/:id/uploads - response contains each upload" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    json_response_uploads = json_response.map { |a| a["datafile_file_name"].split(".")[0] }
    assert_equal @uploads.sort, json_response_uploads.sort
  end

  test "Endpoint api/projects/:id/uploads - each upload contains reference to correct datapackage" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal upload_csv_search["datapackage_id"], @project.datapackage.id
    end
  end

  # api/project/:id/uploads/:table_ref
  test "Endpoint api/projects/:id/uploads/:table_ref - response ok" do
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      assert_response :success
    end
  end

  # this test saves from repeating the group tests on the individual table endpoints
  test "Endpoint api/projects/:id/uploads/:table_ref - table details same from individual and group endpoints" do
    get :index, :id => @project.id
    all_tables_json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      individual_table_json_response = JSON.parse(response.body)
      group_csv_search = all_tables_json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal group_csv_search, individual_table_json_response.except("row_count")
    end
  end

end
