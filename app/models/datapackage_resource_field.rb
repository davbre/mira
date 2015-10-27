class DatapackageResourceField < ActiveRecord::Base
  belongs_to :datapackage_resource
  validates :datapackage_resource_id, presence: true
  validates :name, presence: true
  validates :ftype, presence: true
  validates :order, presence: true
  validates_uniqueness_of :order, scope: :datapackage_resource_id
end
