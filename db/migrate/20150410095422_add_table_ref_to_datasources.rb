class AddTableRefToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :table_ref, :string
  end
end
