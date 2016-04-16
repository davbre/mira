class ApiKeyPermission < ActiveRecord::Base

  enum scope: [:all_projects, :project, :table]
  enum permission: [ :read, :write ]

  belongs_to :api_key
  validates :api_key, presence: true    # using api_key to enforce that api_key exists (instead of using api_key_id)
  validates :permission, presence: true

end
