class DatapackageResource < ActiveRecord::Base
  belongs_to :datapackage
  has_many :datapackage_resource_fields
  validates :datapackage_id, presence: true
  validates :path, presence: true
  validates :schema, presence: true
end
