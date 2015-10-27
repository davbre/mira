require 'test_helper'

class Api::V1::DatapackageResourcesEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::DatapackageResourcesController.new # See http://stackoverflow.com/a/7743176
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test datapackage resources", description: "Upload test project description")
    @project.save
    upload_to_project(@project, [], "uploads/datapackage/good/datapackage.json") # just upload datapackage file
    @dp_file_json = JSON.parse(File.read(@dp_file))
  end

  def teardown
    Project.find(@project.id).destroy
  end

  test "projects/:id/datapackage/resources endpoint should show datapackage resources" do
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

  test "projects/:id/datapackage/resources/:table_ref endpoint should show datapackage resource" do
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

end
