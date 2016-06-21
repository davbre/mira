class AddDatapackageResourceToDatasources < ActiveRecord::Migration
  def change
    add_reference :datasources, :datapackage_resource, index: true, foreign_key: true
  end
end
