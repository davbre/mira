class AddArchivedToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :archived, :boolean, :default => false
  end
end
