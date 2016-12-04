require 'test_helper'
# require_relative '../../app/controllers/api/v1/projects_controller'
# require 'minitest/spec'

class Api::V1::DatasourcesEndpointsTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    Delayed::Worker.delay_jobs = false # turn off queuing
    sign_in users(:one)
    @controller = Api::V1::DatapackageResourcesController.new # See http://stackoverflow.com/a/7743176
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @uploads = ["upload1","upload2"]

    dpfile = "uploads/datapackage/good/datapackage.json"
    @dp = JSON.parse(File.read(Rails.root.join("test/fixtures/", dpfile)))

    upload_to_project(@controller,@project, @uploads, dpfile) # just upload datapackage file

    @dp_file_json = JSON.parse(File.read(@dp_file))
  end

  def teardown
    Project.find(@project.id).destroy
  end

  # api/project/:id/tables
  test "Enpoint api/projects/:id/tables - response ok" do
    get :index, :id => @project.id
    assert_response :success
  end

  test "Endpoint api/projects/:id/tables - response contains same number of tables as specified in datapackage.json" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @dp["resources"].length
  end

  test "Endpoint api/projects/:id/tables - response contains each table uploaded" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    json_response_tables = json_response.map { |a| a["table_ref"] }
    # binding.pry
    @uploads.each do |u|
      assert_includes json_response_tables, u
    end
  end

  test "Endpoint api/projects/:id/tables - each upload contains reference to correct datapackage" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["table_ref"] == upl }
      assert_equal upload_csv_search["datapackage_id"], @project.datapackage.id
    end
  end

  # api/project/:id/uploads/:table_ref
  test "Endpoint api/projects/:id/tables/:table_ref - response ok" do
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      assert_response :success
    end
  end

  # this test saves from repeating the group tests on the individual table endpoints
  test "Endpoint api/projects/:id/tables/:table_ref - table details same from individual and group endpoints" do
    get :index, :id => @project.id
    all_tables_json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      individual_table_json_response = JSON.parse(response.body)
      group_csv_search = all_tables_json_response.detect{ |a| a["table_ref"] == upl }
      assert_equal group_csv_search, individual_table_json_response.except("row_count")
    end
  end

end
