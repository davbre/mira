class AddAddIndexToDatapackageResourceFields < ActiveRecord::Migration
  def change
    add_column :datapackage_resource_fields, :add_index, :boolean, :default => true
  end
end
