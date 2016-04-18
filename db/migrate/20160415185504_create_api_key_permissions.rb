class CreateApiKeyPermissions < ActiveRecord::Migration
  def change
    create_table :api_key_permissions do |t|
      t.integer :api_key_id
      t.integer :permission_scope
      t.integer :permission
      t.integer :project_id
      t.integer :datapackage_resource_id
      t.string :db_table_name

      t.timestamps null: false
    end
  end
end
