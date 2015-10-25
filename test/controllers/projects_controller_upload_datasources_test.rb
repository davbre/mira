require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  setup do
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
  end

  # datasources upload
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
    has_no_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => has_no_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:resources_missing]
  end

  test "should detect when datapackage resources property is not an array" do
    non_array_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_not_array/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => non_array_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:non_array_resources]
  end

  test "should detect when datapackage resources property is missing" do
    empty_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_empty/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => empty_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:resources_missing]
  end

  test "should detect when path is missing" do
    no_path_datapackage = fixture_file_upload("uploads/datapackage/bad_path_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_path_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_path]
    assert expected_error
  end

  test "should detect when schema is missing" do
    no_schema_datapackage = fixture_file_upload("uploads/datapackage/bad_schema_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_schema_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_schema]
    assert expected_error
  end

  test "should detect when path is not a String" do
    not_string_path_dp = fixture_file_upload("uploads/datapackage/bad_path_not_string/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => not_string_path_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_not_string]
    assert expected_error
  end

  test "should detect when path is empty" do
    empty_path_dp = fixture_file_upload("uploads/datapackage/bad_path_empty/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => empty_path_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_empty]
    assert expected_error
  end

  test "should detect when path does not refer to a csv file" do
    path_not_csv_dp = fixture_file_upload("uploads/datapackage/bad_path_not_csv/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => path_not_csv_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_not_csv]
    assert expected_error
  end

  test "should detect when schema is not a Hash" do
    schema_not_hash_dp = fixture_file_upload("uploads/datapackage/bad_schema_not_hash/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_not_hash_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_not_hash]
    assert expected_error
  end

  test "should detect when schema has no fields" do
    schema_no_fields_dp = fixture_file_upload("uploads/datapackage/bad_schema_no_fields/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_no_fields_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_no_fields]
    assert expected_error
  end

  test "should detect when schema fields is not an Array" do
    schema_not_array_dp = fixture_file_upload("uploads/datapackage/bad_schema_not_array/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_not_array_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_not_array]
    assert expected_error
  end

  test "should detect when a schema field does not have both a name and a type" do
    field_not_name_and_type_dp = fixture_file_upload("uploads/datapackage/bad_field_not_name_and_type/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => field_not_name_and_type_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_not_name_and_type]
    assert expected_error
  end

  test "should detect invalid field name" do
    field_invalid_name_dp = fixture_file_upload("uploads/datapackage/bad_field_invalid_name/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => field_invalid_name_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_invalid_name]
    assert expected_error
  end

  test "should detect invalid field type" do
    field_invalid_type_dp = fixture_file_upload("uploads/datapackage/bad_field_invalid_type/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => field_invalid_type_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_invalid_type]
    assert expected_error
  end


end
