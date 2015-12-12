require 'test_helper'

class Api::V1::DatapackageResourceFieldsEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::DatapackageResourceFieldsController.new # See http://stackoverflow.com/a/7743176
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

  test "projects/:id/tables/:table_ref/datapackage/fields endpoint should show datapackage resource fields" do
    # mimic json response using datapackage file
    @dp_file_json["resources"].each do |res|
      mimic_json = []
      table_ref = res["path"].split(".").first
      get :index, :id => @project.id, :table_ref => table_ref
      json_response = JSON.parse(response.body)
      assert_response :success
      assert_not_nil json_response
      res["schema"]["fields"].each_with_index.map do |f,i|
        field_hash = {}
        field_hash["name"] = f["name"]
        field_hash["type"] = f["type"]
        field_hash["order"] = i + 1
        field_hash["format"] = nil
        field_hash["add_index"] = true
        field_hash["big_integer"] = nil
        if f.has_key? "constraints"
          if f["constraints"].has_key? "maximum"
            field_hash["big_integer"] = true if f["constraints"]["maximum"].to_i > BIG_INTEGER_LIMIT
          end
        end
        mimic_json << field_hash
      end
      assert_equal mimic_json, json_response
    end
  end

  test "projects/:id/tables/:table_ref/datapackage/fields/:col_ref endpoint should show datapackage resource field" do
    # mimic json response using datapackage file
    @dp_file_json["resources"].each do |res|
      table_ref = res["path"].split(".").first
      res["schema"]["fields"].each_with_index.map do |f,i|
        get :show, :id => @project.id, :table_ref => table_ref, :col_ref => f["name"]
        json_response = JSON.parse(response.body)
        assert_response :success
        assert_not_nil json_response
        field_hash = {}
        field_hash["name"] = f["name"]
        field_hash["type"] = f["type"]
        field_hash["order"] = i + 1
        field_hash["format"] = nil
        field_hash["add_index"] = true
        field_hash["big_integer"] = nil
        if f.has_key? "constraints"
          if f["constraints"].has_key? "maximum"
            field_hash["big_integer"] = true if f["constraints"]["maximum"].to_i > BIG_INTEGER_LIMIT
          end
        end
        assert_equal field_hash, json_response
      end

    end
  end

end
