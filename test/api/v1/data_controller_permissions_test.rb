require 'test_helper'

class Api::V1::DataControllerTest < ActionController::TestCase

  include Devise::TestHelpers


  setup do
    sign_in users(:one)
    # @project = projects(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @uploads = ["good_upload"]
    upload_to_project(@controller,@project, @uploads, "uploads/datapackage/good/datapackage.json") # just upload datapackage file
    @last_dpr = DatapackageResource.last
    @test_table = Mira::Application.const_get(@last_dpr.db_table_name.capitalize.to_sym)
  end

  test "should return 200 success when reading row data with no API key set" do
    # get first row of data
    get :show, :id => @project.id, :table_ref => @uploads[0], :data_id => 1
    assert_response :success
  end


  test "should return a row of data when no API key set" do
    csv_file = fixture_file_upload("uploads/" + @uploads[0] + ".csv", "text/plain")
    first_row = IO.readlines(csv_file)[1]
    first_row_compare_array = first_row.split(",").map { |e| e.gsub("\"","").gsub("\n","").downcase }
    # get first row of data
    get :show, :id => @project.id, :table_ref => @uploads[0], :data_id => 1
    response_compare_array = JSON.parse(@response.body).except("id").values.map {|e| e.to_s.downcase }
    assert_equal first_row_compare_array, response_compare_array
  end


  test "should not be able to read or write data when global API key set" do
    # read permissions restricted for both :read and :write
    # Cross reference the api data actions. We loop over the API key scopes and
    # then permissions, testing each endpoint.
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

        # just make sure we are referencing the correct data!
        assert_equal @last_dpr.table_ref, @uploads[0]

        # check read endpoints
        get :index, :id => @project.id, :table_ref => @uploads[0]
        assert_response :unauthorized

        post :datatables, :id => @project.id, :table_ref => @uploads[0]
        assert_response :unauthorized

        get :show, :id => @project.id, :table_ref => @uploads[0], :data_id => 1
        assert_response :unauthorized

        get :distinct, :id => @project.id, :table_ref => @uploads[0], :col_ref => "age"
        assert_response :unauthorized

        # check write endpoints
        count_before = @test_table.count
        post :create, :id => @project.id, :table_ref => @uploads[0]
        count_after = @test_table.count
        assert_response :unauthorized
        assert_equal count_before, count_after

        patch :update, :id => @project.id, :table_ref => @uploads[0], :data_id => 1
        assert_response :unauthorized

        count_before = @test_table.count
        delete :destroy, :id => @project.id, :table_ref => @uploads[0], :data_id => 1
        count_after = @test_table.count
        assert_response :unauthorized
        assert_equal count_before, count_after


      end

    end
  end

  test "should be able to write/update/delete data when using global write API key" do
    skip
  end

  test "should be able to write/update/delete data when using project write API key" do
    skip
  end

end
