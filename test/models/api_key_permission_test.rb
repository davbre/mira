require 'test_helper'

class ApiKeyPermissionTest < ActiveSupport::TestCase

  setup do
    @key = api_keys(:one)
  end

  test "should save with an existant API key id + permission + scope = all + NO project_id " do
    scope = ApiKeyPermission.permission_scopes[:global]
    perm = ApiKeyPermission.permissions[:read]
    akp = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: scope, permission: perm, project_id: nil)
    assert akp.valid?
  end

  test "should save with an existant API key id + permission + scope = project + project_id " do
    scope = ApiKeyPermission.permission_scopes[:global]
    perm = ApiKeyPermission.permissions[:read]
    akp = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: scope, permission: perm, project_id: projects(:one))
    assert akp.valid?
  end

  test "should NOT save with an existant API key id + permission + WITHOUT scope + project_id " do
    perm = ApiKeyPermission.permissions[:read]
    akp = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: nil, permission: perm, project_id: projects(:one))
    assert_not akp.valid?
  end

  test "should NOT save with an existant API key id + WITHOUT permission + scope + project_id " do
    scope = ApiKeyPermission.permission_scopes[:global]
    akp = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: scope, permission: nil, project_id: projects(:one))
    assert_not akp.valid?
  end

  test "should NOT save when permission already exists" do
    # not a big deal but should enforce this
    skip
  end

end
