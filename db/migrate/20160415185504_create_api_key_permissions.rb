class CreateApiKeyPermissions < ActiveRecord::Migration
  def change
    create_table :api_key_permissions do |t|
      t.integer :api_key_id
      t.integer :scope
      t.integer :project_id

      t.integer :datapackage_resource_id
      t.string :db_table_name

      t.integer :permission

      t.timestamps null: false
    end
  end
end
