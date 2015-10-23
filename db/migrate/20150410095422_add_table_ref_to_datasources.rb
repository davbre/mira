class AddTableRefToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :table_ref, :text
    add_index :datasources, :table_ref
  end
end
