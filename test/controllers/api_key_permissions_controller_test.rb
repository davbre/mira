
require 'test_helper'

class ApiKeyPermissionsControllerTest < ActionController::TestCase


  setup do
    @user1 = users(:one)
    @key_permission = api_key_permissions(:one)
    sign_in users(:one)
  end

  # index
  test "should not get INDEX if signed out" do
    sign_out users(:one)
    get :index, :user_id => @user1.id, :api_key_id => @key_permission.api_key_id
    assert_redirected_to new_user_session_path
  end

  test "should get INDEX if signed in" do
    get :index, :user_id => @user1.id, :api_key_id => @key_permission.api_key_id
    assert_response :success
  end

  ###################################################################################
  # show - no test as we don't have a SHOW action for individual API key permissions
  ###################################################################################

  # new
  test "should not get NEW if signed out" do
    sign_out users(:one)
    get :new, :user_id => @user1.id, :api_key_id => @key_permission.api_key_id
    assert_redirected_to new_user_session_path
  end

  test "should get NEW if signed in" do
    get :new, :user_id => @user1.id, :api_key_id => @key_permission.api_key_id
    assert_response :success
  end

  # create
  test "should not CREATE global permission if signed out" do
    sign_out users(:one)
    assert_no_difference('ApiKeyPermission.count') do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => ["all"], \
                                     :permission => :read }
    end
    assert_redirected_to new_user_session_path
  end

  test "should CREATE global permission if signed in" do
    assert_difference('ApiKeyPermission.count',1) do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => ["all"], \
                                     :permission => :read }
    end
    assert_redirected_to user_api_key_api_key_permissions_path
  end

  test "should not CREATE individual project permission if signed out" do
    sign_out users(:one)
    assert_no_difference('ApiKeyPermission.count') do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => [projects(:two).id], \
                                     :permission => :read }
    end
    assert_redirected_to new_user_session_path
  end

  test "should CREATE individual project permission if signed in" do
    assert_difference('ApiKeyPermission.count',1) do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => [projects(:two).id], \
                                     :permission => :read }
    end
    assert_redirected_to user_api_key_api_key_permissions_path
  end


  # send non-numeric project ids  => should not add permission
  test "should not add permission if project ids non-numeric" do
    assert_no_difference('ApiKeyPermission.count') do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => ["a", "b", "c"], \
                                     :permission => :read }
    end
    assert_redirected_to user_api_key_api_key_permissions_path
  end

  # send project ids not belonging to current_user => should not add permission
  # projects(:three) belongs to different user
  test "should not add permission if not project of current user" do
    assert_no_difference('ApiKeyPermission.count') do
      post :create, :user_id => @user1.id, \
           :api_key_id => @key_permission.api_key_id, \
           :api_key_permission =>  { :projects => [projects(:three).id], \
                                     :permission => :read }
    end
    assert_redirected_to user_api_key_api_key_permissions_path
  end


end
