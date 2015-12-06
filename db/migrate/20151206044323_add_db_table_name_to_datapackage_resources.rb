class AddDbTableNameToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :db_table_name, :text
  end
end
