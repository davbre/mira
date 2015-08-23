require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

 include Devise::TestHelpers

  setup do
    sign_in users(:one)    
    @project = projects(:one)
  end

  # index
  test "should get index" do
    get :index
    assert_response :success
    sign_out users(:one)
    assert_response :success
    assert_not_nil assigns(:projects) # i.e. creates @projects variable for use in view
  end

  # new
  test "should get new if signed in" do
    get :new
    assert_response :success
  end

  test "should not get new if signed out" do
    sign_out users(:one)
    get :new
    assert_redirected_to new_user_session_path
  end

  # create
  test "should create project if signed in" do
    assert_difference('Project.count') do
      post :create, project: { name: "New test project name", description: "New test project description" }
    end
    assert_redirected_to project_path(assigns(:project))
  end

  test "should not create project if signed out" do
    sign_out users(:one)
    assert_no_difference('Project.count') do
      post :create, project: { name: "New test project name", description: "New test project description" }
    end
    assert_redirected_to new_user_session_path
  end

  # show
  test "should show project" do
    get :show, id: @project
    assert_response :success
    sign_out users(:one)
    assert_response :success
  end

  # edit
  test "should get edit if signed in and owner of project" do
    get :edit, id: @project
    assert_response :success
  end

  test "should not get edit if signed out" do
    sign_out users(:one)
    get :edit, id: @project
    assert_redirected_to new_user_session_path
  end

  test "should not get edit if not project owner" do
    sign_out users(:one)
    sign_in users(:two)
    get :edit, id: @project
    assert_redirected_to root_path
  end

  # update
  test "should update project if signed in and owner of project" do
    new_proj_name = "New project name"
    new_proj_desc = "New project description"
    patch :update, id: @project, project: { name: new_proj_name, description: new_proj_desc }
    assert_equal(Project.find(@project.id).name, new_proj_name)
  end

  test "should not update project if signed out" do
    sign_out users(:one)
    new_proj_name = "New project name"
    new_proj_desc = "New project description"
    patch :update, id: @project, project: { name: new_proj_name, description: new_proj_desc }
    assert_not_equal(Project.find(@project.id).name, new_proj_name)
    assert_redirected_to new_user_session_path
  end

  test "should not update project if not owner of project" do
    sign_out users(:one)
    sign_in users(:two)
    new_proj_name = "New project name"
    new_proj_desc = "New project description"
    patch :update, id: @project, project: { name: new_proj_name, description: new_proj_desc }
    assert_not_equal(Project.find(@project.id).name, new_proj_name)
    assert_redirected_to root_path
  end

  # destroy
  test "should destroy project if signed in and owner of project" do
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end
    assert_redirected_to projects_path
  end

  test "should not destroy project if signed out" do
    sign_out users(:one)
    assert_no_difference('Project.count') do
      delete :destroy, id: @project
    end
    assert_redirected_to new_user_session_path
  end

  test "should delete uploads and log files on delete" do
    skip
  end

  test "should delete xy tables on delete" do
  end


  # uploads
  test "should detect when no files uploaded" do
    Delayed::Worker.delay_jobs = false # turn off queuing

    user = users(:one)
    project = user.projects.build(name: "Upload test project", description: "Upload test project description")
    project.save
    post :upload_ds, id: project.id, :datafiles => [ ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "you must upload one or more csv files along with their datapackage.json file"
    assert no_datapackage
  end

  test "should detect when no datapackage.json is uploaded" do

    Delayed::Worker.delay_jobs = false # turn off queuing

    user = users(:one)
    project = user.projects.build(name: "Upload test project", description: "Upload test project description")
    project.save
    upload1 = fixture_file_upload("uploads/upload1.csv", "text/csv")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    # datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: project.id, :datafiles => [ upload1, upload2 ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "no datapackage.json was uploaded"
    assert no_datapackage
  end

  test "should detect when no csv files are uploaded" do
    Delayed::Worker.delay_jobs = false # turn off queuing

    user = users(:one)
    project = user.projects.build(name: "Upload test project", description: "Upload test project description")
    project.save
    upload1 = fixture_file_upload("uploads/upload1.txt", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.txt", "text/plain")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: project.id, :datafiles => [ upload1, upload2, datapackage ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "no csv files were uploaded"
    assert no_datapackage

  end

  test "should detect when a non-csv/non-datapackage.json file is uploaded" do
    Delayed::Worker.delay_jobs = false # turn off queuing

    user = users(:one)
    project = user.projects.build(name: "Upload test project", description: "Upload test project description")
    project.save
    upload1 = fixture_file_upload("uploads/upload1.txt", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: project.id, :datafiles => [ upload1, upload2, datapackage ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "only csv files can be uploaded along with their datapackage.json file"
    assert no_datapackage
  end

  test "should detect when datapackage.json does not contain a resource section for each csv file" do
    skip
  end

  test "should be able to link to datapackage.json" do
    skip
  end

  test "should be able to link to each csv file" do
    skip
  end

  test "should be able to read log files..." do
    skip
  end
  
  test "should handle other delimiters" do
    skip
  end
  
  test "datapackage should contain dialect -> delimiter for each table" do
    skip
  end

  test "renaming datapackage.json" do
    skip
  end

  test "archiving works properly - datapackage, csv files, log files (?)" do
    skip
  end

  test "datapackage_id is working properly...i.e. reference the correct datapackage file" do
    skip
  end

  test "archived boolean is flagged correctly, i.e. on first load = false and subsequent loads = true" do
    skip
  end

  test "deleting project deletes all files...datasources, logs, db tables, etc" do
    skip
  end

  test "datapackage with columns in RESERVED_COLUMN_NAMES should be rejected" do
    skip
  end

  test "all scopes" do
    skip
  end
end
