class AddPrivateToDatapackageResourceFields < ActiveRecord::Migration
  def change
    add_column :datapackage_resource_fields, :private, :boolean, :default => false
  end
end
