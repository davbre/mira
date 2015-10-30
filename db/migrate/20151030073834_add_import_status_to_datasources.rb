class AddImportStatusToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :import_status, :integer
  end
end
