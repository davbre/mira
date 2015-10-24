require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  setup do
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
  end

  # datapackage upload
  test "should detect when datapackage already uploaded" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    another_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:already_uploaded]
    assert expected_error
  end

  test "should detect when no datapackage uploaded" do
    post :upload_datapackage, id: @project.id, :datapackage => nil
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:no_upload]
    assert expected_error
  end

  test "should detect when bad json" do
    bad_json_datapackage = fixture_file_upload("uploads/datapackage/bad_not_json/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => bad_json_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:bad_json]
    assert expected_error
  end

  test "should detect when datapackage has no resources property" do
    has_no_resources_dp = fixture_file_upload("uploads/datapackage/bad_no_resources/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => has_no_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:no_resources]
  end

  test "should detect when datapackage resources property is not an array" do
    non_array_resources_dp = fixture_file_upload("uploads/datapackage/bad_non_array_resources/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => non_array_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:non_array_resources]
  end

  test "should detect when datapackage resources property is empty" do
    empty_resources_dp = fixture_file_upload("uploads/datapackage/bad_empty_resources/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => empty_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:no_resources]
  end

  test "should detect when path is missing" do
    no_path_datapackage = fixture_file_upload("uploads/datapackage/bad_missing_path/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_path_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_path]
    assert expected_error
  end

  test "should detect when schema is missing" do
    no_schema_datapackage = fixture_file_upload("uploads/datapackage/bad_missing_schema/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_schema_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_schema]
    assert expected_error
  end

  test "should detect when path is not a String" do
    skip
  end

  test "should detect when path is empty" do
    skip
  end

  test "should detect when path does not refer to a csv file" do
    skip
  end

  test "should detect when schema is not a Hash" do
    skip
  end

  test "should detect when schema has no fields" do
    skip
  end

  test "should detect when schema fields is not an Array" do
    skip
  end

  test "should detect when a schema field does not both a name and a type" do
    skip
  end

  test "should detect invalid field name" do
    skip
  end

  test "should detect invalid field type" do
    skip
  end
end
