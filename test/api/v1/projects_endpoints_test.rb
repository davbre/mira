require 'test_helper'

class Api::V1::ProjectsEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::ProjectsController.new # See http://stackoverflow.com/a/7743176
    sign_in users(:one)
    # @project = projects(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save

    # @upload = "upload1"
    # dp_file = fixture_file_upload("uploads/datapackage.json", "application/json")
    # csv_file = fixture_file_upload("uploads/" + @upload + ".csv", "text/plain")
    #
    # dp = @project.datasources.create(datafile: File.open(dp_file), datafile_file_name: "datapackage.json")
    # dp.save
    #
    # ds = @project.datasources.create(datafile: csv_file, datafile_file_name: @upload + ".csv", datapackage_id: dp.id)
    # ds.save
    # ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
    # ds.save
    #
    # datapackage = JSON.parse(File.read(dp_file.tempfile.path))
    # ProcessCsvUpload.new(ds.id).perform
  end


  test "projects/ endpoint should return list of projects including newly created one" do
    get :index #, {}, { "Accept" => "application/json" }
    json_response = JSON.parse(response.body)
    json_project = json_response.detect{ |a| a["id"] == @project.id }
    assert_response :success
    refute_nil json_project
    assert json_project["name"] == @project.name && json_project["description"] == @project.description \
           && json_project["id"] == @project.id && json_project["user_id"] == @user.id
  end

  test "projects/:id endpoint should return newly created project" do
    get :show, :id => @project.id
    json_project = JSON.parse(response.body)
    assert json_project["name"] == @project.name && json_project["description"] == @project.description \
           && json_project["id"] == @project.id && json_project["user_id"] == @user.id
  end


  test "should not be able to read project metadata when API key set" do
    # this is not currently the case! I.e. project metadata can be read
    [:global, :project].each do |scope|

      project_id = (scope == :global) ? nil : @project.id

      [:read, :write].each_with_index do |perm,ndx|
        new_key = ApiKey.new(user_id: @user.id, token: ndx.to_s[0]*24, description: "New API key")
        new_key.save
        permission = ApiKeyPermission.new(api_key_id: new_key.id, \
                                          permission_scope: scope, \
                                          permission: perm,
                                          project_id: project_id)
        permission.save

        get :index, :id => @project.id, :table_ref => @uploads[0]
        assert_response :unauthorized

      end
    end
  end

end
