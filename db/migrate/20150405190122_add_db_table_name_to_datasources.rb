class AddDbTableNameToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :db_table_name, :string
    add_index :datasources, :db_table_name
  end
end
