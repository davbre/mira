class DatapackageResource < ActiveRecord::Base
  belongs_to :datapackage
  has_many :datapackage_resource_fields
  has_one :datasource  # this is not required. Only set when corresponding file
                       # has been uploaded
  validates :datapackage_id, presence: true
  validates :path, presence: true
  validates :schema, presence: true

  attr_accessor :basket # just extra variable for convenience
end
