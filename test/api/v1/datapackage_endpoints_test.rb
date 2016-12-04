require 'test_helper'

class Api::V1::DatapackageEndpointsTest < ActionController::TestCase

  setup do
    @controller = Api::V1::DatapackagesController.new # See http://stackoverflow.com/a/7743176
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @datapackage = Datapackage.new(project_id: @project.id, public_url: "dummy/url/datapackage.json")
    @datapackage.save
  end

  def teardown
    Project.find(@project.id).destroy
  end

  test "projects/:id/datapackage endpoint should return datapackage data" do
    get :show, :id => @project.id
    json_response = JSON.parse(response.body)
    assert_response :success
    assert_equal @datapackage.id, json_response["id"]
    assert_equal @project.id, json_response["project_id"]
    assert_equal @datapackage.public_url, json_response["public_url"]
  end


end
