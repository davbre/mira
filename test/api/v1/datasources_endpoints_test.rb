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
    upload_to_project(@project, @uploads, "uploads/datapackage/good/datapackage.json") # just upload datapackage file
    @dp_file_json = JSON.parse(File.read(@dp_file))
  end

  # api/project/:id/tables
  test "Enpoint api/projects/:id/tables - response ok" do
    get :index, :id => @project.id
    assert_response :success
  end

  test "Endpoint api/projects/:id/tables - response contains same number of uploads" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @uploads.length
  end

  test "Endpoint api/projects/:id/tables - response contains each upload" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    json_response_uploads = json_response.map { |a| a["table_ref"] }
    assert_equal json_response_uploads.sort, @uploads.sort
  end

  test "Endpoint api/projects/:id/tables - each upload contains reference to correct datapackage" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal upload_csv_search["datapackage_id"], @project.datapackage.id
    end
  end

  test "Endpoint api/projects/:id/tables - each upload references expected database table name" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal upload_csv_search["db_table_name"],
             Rails.configuration.x.db_table_prefix.downcase + @project.id.to_s + "_" + upload_csv_search["id"].to_s
    end
  end

  # api/project/:id/tables/:table_ref
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
      group_csv_search = all_tables_json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal group_csv_search, individual_table_json_response.except("row_count")
    end
  end

  test "Endpoint api/projects/:id/tables/:table_ref - returns correct row count" do # row count only appears in the individual table endpoint
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      row_count = File.open(csv_file,"r").readlines.size
      assert_equal row_count, json_response["row_count"] + 1 # extra 1 accounts for header row
    end
  end


  # api/projects/:id/tables/:table_ref/columns
  test "Endpoint api/projects/:id/tables/:table_ref/columns - returns correct columns" do
    @uploads.each do |upl|
      get :column_index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_header_columns = CSV.open(csv_file, 'r') { |csv| csv.first } # http://stackoverflow.com/a/18113090/1002140
      json_columns = json_response.except("id").keys # remove id before assert equal
      assert_equal csv_header_columns, json_columns
    end
  end

  test "Endpoint api/projects/:id/tables/:table_ref/columns - returns correct column metadata" do
    @uploads.each do |upl|
      get :column_index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      mapped_col_types = map_datapackage_column_types(@dp_file_json, upl + ".csv")
      assert_equal mapped_col_types, json_response.except("id")
    end
  end

  # api/projects/:id/tables/:table_ref/columns/:col_ref
  test "Endpoint api/projects/:id/tables/:table_ref/columns/:col_ref - returns correct column + metadata" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_header_columns = CSV.open(csv_file, 'r') { |csv| csv.first } # http://stackoverflow.com/a/18113090/1002140

      mapped_col_types = map_datapackage_column_types(@dp_file_json, upl + ".csv")

      csv_header_columns.each do |col|
        get :column_show, :id => @project.id, :table_ref => upl, :col_ref => col
        json_response = JSON.parse(response.body)
        assert_equal col, json_response["name"]
        assert_equal mapped_col_types[col], json_response["type"]
      end
    end
  end

end
