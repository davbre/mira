require 'test_helper'

class DatasourcesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @upload_files = ["upload1","upload2"]
    upload_to_project(@project,@upload_files)
  end

  # destroy
  test "should destroy datasource if signed in and owner of project" do
    assert_difference('Project.find(' + @project.id.to_s + ')' + '.datasources.count', -1) do
      delete :destroy, project_id: @project, id: @project.datasources.where(table_ref: @upload_files[0]).first.id
    end
    assert_redirected_to project_datasources_path
  end

  test "should not destroy datasource if signed out" do
    sign_out users(:one)
    assert_no_difference('Project.find(' + @project.id.to_s + ')' + '.datasources.count', -1) do
      delete :destroy, project_id: @project, id: @project.datasources.where(table_ref: @upload_files[0]).first.id
    end
    assert_redirected_to new_user_session_path
  end

  test "should not destroy datasource if not owner" do
    sign_out users(:one)
    sign_out users(:two)
    assert_no_difference('Project.find(' + @project.id.to_s + ')' + '.datasources.count', -1) do
      delete :destroy, project_id: @project, id: @project.datasources.where(table_ref: @upload_files[0]).first.id
    end
    assert_redirected_to new_user_session_path
  end

  test "should not delete datapackage.json if exists other associated csv files" do
    datapackage_id = Datasource.where(table_ref: @upload_files[0]).first.datapackage_id
    delete :destroy, project_id: @project, id: @project.datasources.where(table_ref: @upload_files[0]).first.id
    assert_not_nil Datasource.where(id: datapackage_id).first
  end

  test "should delete datapackage.json if all associated csv files are deleted" do
    datapackage_id = Datasource.where(table_ref: @upload_files[0]).first.datapackage_id
    @upload_files.each do |u|
      delete :destroy, project_id: @project, id: @project.datasources.where(table_ref: u).first.id
    end
    assert_nil Datasource.where(id: datapackage_id).first
  end


  # test "should log errors when wrong mime-type detected (use airport-codes.csv which contains html" do
  #   skip
  # end
  #
  # test "single and double quoting characters in upload" do
  #   skip
  # end
  #
  # test "should not return distinct values for non-text/string columns" do
  #   skip
  # end
  #
  # test "should return a message in json saying distinct values not supported for column when not text/string" do
  #   skip
  # end
  #
  # test "should return paged distinct values for text/string columns" do
  #   skip
  # end
  #
  # test "table index should only return tables (and not datapackage files)" do
  #   skip
  # end
  #
  # test "datapackage index should only return datapackage files" do
  #   skip
  # end
end
