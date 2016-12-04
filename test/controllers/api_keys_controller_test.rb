require 'test_helper'

class ApiKeysControllerTest < ActionController::TestCase

  setup do
    @user1 = users(:one)
    @key = api_keys(:one)
    sign_in users(:one)
  end

  # index
  test "should not get INDEX if signed out" do
    sign_out users(:one)
    get :index, :user_id => @user1.id
    assert_redirected_to new_user_session_path
  end

  test "should get INDEX if signed in" do
    get :index, :user_id => @user1.id
    assert_response :success
  end

  # show
  test "should not get SHOW if signed out" do
    sign_out users(:one)
    get :show, :user_id => @user1.id, id: @key.id
    assert_redirected_to new_user_session_path
  end

  test "should get SHOW if signed in" do
    get :show, :user_id => @user1.id, id: @key.id
    assert_response :success
  end

  # new
  test "should not get NEW if signed out" do
    sign_out users(:one)
    get :new, :user_id => @user1.id
    assert_redirected_to new_user_session_path
  end

  test "should get NEW if signed in" do
    get :new, :user_id => @user1.id
    assert_response :success
  end

  # create
  test "should not CREATE if signed out" do
    sign_out users(:one)
    get :new, :user_id => @user1.id
    assert_redirected_to new_user_session_path
  end

  test "should CREATE if signed in" do
    assert_difference('ApiKey.count',1) do
      post :create, :user_id => @user1.id \
           , api_key: { description: "New API key", \
                        token: "123456789012345678901234" }
    end
    assert_redirected_to user_api_keys_path
  end

  # edit
  test "should not get EDIT if signed out" do
    sign_out users(:one)
    get :edit, :user_id => @user1.id, id: @key.id
    assert_redirected_to new_user_session_path
  end

  test "should get EDIT if signed in" do
    get :edit, :user_id => @user1.id, id: @key.id
    assert_response :success
  end

  # update
  test "should not UPDATE if signed out" do
    sign_out users(:one)
    new_desc = "New API key description"
    patch :update,:user_id => @user1.id, :id => @key.id, api_key: { description: new_desc }
    assert_not_equal(ApiKey.find(@key.id).description, new_desc)
    assert_redirected_to new_user_session_path
  end

  test "should UPDATE if signed in" do
    new_desc = "New API key description"
    patch :update,:user_id => @user1.id, :id => @key.id, api_key: { description: new_desc }
    assert_equal(ApiKey.find(@key.id).description, new_desc)
  end

  # destroy
  test "should not DESTROY if signed out" do
    sign_out users(:one)
    assert_no_difference('users(:one).api_keys.count') do
      delete :destroy, :user_id => @user1.id, :id => @key.id
    end
    assert_redirected_to new_user_session_path
  end

  test "should DESTROY if signed in" do
    assert_difference('users(:one).api_keys.count', -1) do
      delete :destroy, :user_id => @user1.id, :id => @key.id
    end
    assert_redirected_to user_api_keys_path
  end

end
