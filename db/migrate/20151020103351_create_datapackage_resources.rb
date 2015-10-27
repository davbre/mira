class CreateDatapackageResources < ActiveRecord::Migration
  def change
    create_table :datapackage_resources do |t|
      t.integer :datapackage_id
      t.text :path
      t.text :format
      t.text :delimiter
      t.text :mediatype

      t.timestamps null: false
    end
  end
end
