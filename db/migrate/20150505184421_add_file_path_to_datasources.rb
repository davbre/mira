class AddFilePathToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :public_url, :text
  end
end
