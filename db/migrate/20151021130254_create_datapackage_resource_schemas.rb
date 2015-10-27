class CreateDatapackageResourceSchemas < ActiveRecord::Migration
  def change
    create_table :datapackage_resource_fields do |t|
      t.references :datapackage_resource, index: true
      t.text :name
      t.text :ftype # seems type is reserved word
      t.integer :order

      t.timestamps null: false
    end
    add_foreign_key :datapackage_resource_fields, :datapackage_resources
  end
end
