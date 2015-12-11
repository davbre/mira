require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

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

  test "should create log and upload folders" do
    post :create, project: { name: "New test project name", description: "New test project description" }
    last_project = Project.last
    assert File.directory?(last_project.job_log_path)
    assert File.directory?(last_project.upload_path)
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
    assert_difference('users(:one).projects.count', -1) do
      delete :destroy, id: @project
    end
    assert_redirected_to projects_path
  end

  test "should not destroy project if signed out" do
    sign_out users(:one)
    assert_no_difference('users(:one).projects.count') do
      delete :destroy, id: @project
    end
    assert_redirected_to new_user_session_path
  end

  test "should delete uploads and log files on delete" do
    user = users(:one)
    project = user.projects.build(name: "Testing deletion of uploads and logs", description: "Upload test project description")
    project.save
    upload_files = ["upload1","upload2"]
    upload_to_project(project, upload_files)
    relevant_project_id = Project.last.id
    relevant_project_log_path = Project.last.job_log_path
    relevant_project_upload_path = Project.last.upload_path
    delete :destroy, id: relevant_project_id
    refute File.directory?(relevant_project_log_path)
    refute File.directory?(relevant_project_upload_path)
  end

  test "should delete xy tables on delete" do
    user = users(:one)
    project = user.projects.build(name: "Testing deletion of uploads and logs", description: "Upload test project description")
    project.save
    upload_files = ["upload1","upload2"]
    upload_to_project(project, upload_files)
    db_table_names = []
    upload_files.each do |ul|
      db_table_names << DatapackageResource.where(datapackage_id: project.datapackage, table_ref: ul).first.db_table_name
    end
    delete :destroy, id: Project.last.id
    db_table_names.each do |dbt|
      refute ActiveRecord::Base.connection.table_exists? dbt
    end
  end


end
