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


  test "should NOT return a row of data when API key set" do
    # create key
    # create read permission on this project
    # 'get' data without API key in header
    # assert there is an error response
    skip
  end
end
