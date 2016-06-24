class AddImportedRowsToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :imported_rows, :integer
  end
end
