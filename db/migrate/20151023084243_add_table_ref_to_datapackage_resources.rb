class AddTableRefToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :table_ref, :text
    add_index :datapackage_resources, :table_ref
  end
end
