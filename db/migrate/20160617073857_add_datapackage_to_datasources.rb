class AddDatapackageToDatasources < ActiveRecord::Migration
  def change
    add_reference :datasources, :datapackage, index: true, foreign_key: true
  end
end
