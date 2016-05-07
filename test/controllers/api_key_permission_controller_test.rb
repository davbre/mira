
require 'test_helper'

class ApiKeyPermissionControllerTest < ActionController::TestCase
  test "should get new" do
    skip
  end

  # send non-numeric project ids  => should not add permission
  # send project ids not belonging to current_user => should not add permission

  # add global read API key, should lock down all projects



  #
  # test "should get create" do
  #   get :create
  #   assert_response :success
  # end
  #
  # test "should get edit" do
  #   get :edit
  #   assert_response :success
  # end
  #
  # test "should get update" do
  #   get :update
  #   assert_response :success
  # end
  #
  # test "should get destroy" do
  #   get :destroy
  #   assert_response :success
  # end

end
