class AddDatapackageIdToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :datapackage_id, :integer
  end
end
