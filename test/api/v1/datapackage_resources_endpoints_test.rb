require 'test_helper'

class Api::V1::DatapackageResourcesEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::DatapackageResourcesController.new # See http://stackoverflow.com/a/7743176
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test datapackage resources", description: "Upload test project description")
    @project.save
    upload_to_project(@controller, @project, [], "uploads/datapackage/good/datapackage.json") # just upload datapackage file
    @dp_file_json = JSON.parse(File.read(@dp_file))
  end

  def teardown
    Project.find(@project.id).destroy
  end

  test "projects/:id/tables endpoint should show tables created on datapackage upload" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert_response :success
    json_response.each do |resource|
      dp_file_resource = @dp_file_json["resources"].find { |r| r["path"] == resource["path"] } # get resource info from datapackage file
      assert_equal @project.datapackage.id, resource["datapackage_id"]
      assert_not_nil dp_file_resource
      assert_equal dp_file_resource["dialect"]["delimiter"], resource["delimiter"]
      assert_equal dp_file_resource["format"], resource["format"]
      assert_equal dp_file_resource["path"].split(".").first, resource["table_ref"]
    end
  end

  test "projects/:id/tables/:table_ref endpoint should show datapackage resource" do
    @dp_file_json["resources"].each do |res|
      table_ref = res["path"].split(".").first
      get :show, :id => @project.id, :table_ref => table_ref
      json_response = JSON.parse(response.body)
      assert_response :success
      assert_not_nil json_response
      assert_equal @project.datapackage.id, json_response["datapackage_id"]
      assert_equal res["dialect"]["delimiter"], json_response["delimiter"]
      assert_equal res["format"], json_response["format"]
      assert_equal res["path"].split(".").first, json_response["table_ref"]
    end
  end

  test "Endpoint api/projects/:id/tables/:table_ref - returns correct row count" do # row count only appears in the individual table endpoint
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      # csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      # row_count = File.open(csv_file,"r").readlines.size
      row_count = csv_line_count(upl)
      assert_equal row_count - 1, json_response["imported_rows"] # extra 1 accounts for header row
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
      assert_equal csv_header_columns.sort, json_columns.sort
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
