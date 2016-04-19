class ApiKeyPermission < ActiveRecord::Base

  enum permission_scope: [:global, :project, :table]
  enum permission: [ :read, :write ]

  belongs_to :api_key
  validates :api_key, presence: true    # using api_key to enforce that api_key exists (instead of using api_key_id)
  validates :permission, presence: true
  validates :permission_scope, presence: true

end
