class AddImportedRowsToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :imported_rows, :integer
  end
end
