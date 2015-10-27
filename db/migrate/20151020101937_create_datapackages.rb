class CreateDatapackages < ActiveRecord::Migration
  def change
    create_table :datapackages do |t|
      t.references :project, index: true
      t.text :public_url
      t.timestamps null: false
    end
    add_foreign_key :datapackages, :projects
  end
end
