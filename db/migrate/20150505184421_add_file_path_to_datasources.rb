class AddFilePathToDatasources < ActiveRecord::Migration
  def change
    add_column :datasources, :public_url, :text
    add_column :datasources, :s3_region, :string
  end
end
