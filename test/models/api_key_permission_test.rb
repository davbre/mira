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
    project = projects(:one)
    scope = ApiKeyPermission.permission_scopes[:project]
    perm = ApiKeyPermission.permissions[:read]
    akp = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: scope, permission: perm, project_id: project)
    akp.save
    akp_same = ApiKeyPermission.new(api_key_id: @key.id, permission_scope: scope, permission: perm, project_id: project)
    assert_not akp_same.valid?
  end

end
