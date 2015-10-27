require 'test_helper'

class Api::V1::DatapackageResourceFieldsEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::DatapackageResourceFieldsController.new # See http://stackoverflow.com/a/7743176
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

  test "projects/:id/datapackage/resources/:table_ref/fields endpoint should show datapackage resource fields" do
    @dp_file_json["resources"].each do |res|
      table_ref = res["path"].split(".").first
      get :index, :id => @project.id, :table_ref => table_ref
      json_response = JSON.parse(response.body)
      assert_response :success
      assert_not_nil json_response
      # mimic json response using datapackage file
      mimic_json = res["schema"]["fields"].each_with_index.map { |f,i| {"name" => f["name"], "ftype" => f["type"], "order" => i + 1} }
      assert_equal mimic_json, json_response
    end
  end

end
