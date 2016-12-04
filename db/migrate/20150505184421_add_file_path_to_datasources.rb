class AddFilePathToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :logfile_path, :text
  end
end
