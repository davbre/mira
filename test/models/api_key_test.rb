require 'test_helper'

class ApiKeyTest < ActiveSupport::TestCase

  setup do
    @ok_token = "123456789012345678901234"
  end

  test "should not save without a user" do
    k = ApiKey.new(token: @ok_token)
    assert_not k.save
  end

  test "should not save without an api token" do
    k = ApiKey.new(user_id: users(:one).id, token: "")
    assert_not k.save
  end

  test "should not save with a non-existant user id" do
    k = ApiKey.new(user_id: 999999, token: @ok_token)
    assert_not k.save
  end

  test "should not save token with length not 24" do
    short_token = "1234"
    long_token = "12345678901234567890123456789012345678901234567890"
    k1 = ApiKey.new(user_id: users(:one).id, token: short_token)
    k2 = ApiKey.new(user_id: users(:one).id, token: long_token)
    assert_not k1.save
    assert_not k2.save
  end

end
