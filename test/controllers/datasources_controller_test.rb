require 'test_helper'

class DatasourcesControllerTest < ActionController::TestCase

  setup do
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @upload_files = ["upload1","upload2"]
    upload_to_project(@project,@upload_files)
    Delayed::Worker.delay_jobs = false # turn off queuing
  end

  # destroy
  test "should destroy datasource if signed in and owner of project" do
    destroy_csv = @upload_files[0]
    relevant_datasource = @project.datasources.where(table_ref: destroy_csv).first
    assert_difference('Project.find(' + @project.id.to_s + ')' + '.datasources.count', -1) do
      delete :destroy, project_id: @project, id: relevant_datasource.id
    end
    assert_empty Datasource.where(id: relevant_datasource.id)
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

  test "should drop associated database table" do
    destroy_csv = @upload_files[0]
    relevant_datasource = @project.datasources.where(table_ref: destroy_csv).first
    relevant_db_table_name = relevant_datasource.db_table_name
    assert ActiveRecord::Base.connection.table_exists? relevant_db_table_name
    delete :destroy, project_id: @project, id: relevant_datasource.id
    refute ActiveRecord::Base.connection.table_exists? relevant_db_table_name
  end

  test "should delete associated upload" do
    destroy_csv = @upload_files[0]
    relevant_datasource = @project.datasources.where(table_ref: destroy_csv).first
    # assert file exists, delete, then refute it exists
    assert File.file?(@project.upload_path + relevant_datasource.datafile_file_name)
    delete :destroy, project_id: @project, id: relevant_datasource.id
    refute File.file?(@project.job_log_path + relevant_datasource.datafile_file_name)
  end

  test "should delete associated log file" do
    destroy_csv = @upload_files[0]
    relevant_datasource = @project.datasources.where(table_ref: destroy_csv).first
    # assert file exists, delete, then refute it exists
    assert File.file?(@project.job_log_path + relevant_datasource.datafile_file_name + ".log")
    delete :destroy, project_id: @project, id: relevant_datasource.id
    refute File.file?(@project.job_log_path + relevant_datasource.datafile_file_name + ".log")
  end


end
