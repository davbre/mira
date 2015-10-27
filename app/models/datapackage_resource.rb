class DatapackageResource < ActiveRecord::Base
  belongs_to :datapackage
  has_many :datapackage_resource_fields
  belongs_to :datasource  # this is not required. Only set when corresponding file
                       # has been uploaded
  validates :datapackage_id, presence: true
  validates :path, presence: true
  validates :delimiter, presence: true
  validates :quote_character, presence: true
  validates :table_ref, presence: true

  attr_accessor :basket # just extra variable for convenience
end
