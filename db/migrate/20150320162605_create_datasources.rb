class CreateDatasources < ActiveRecord::Migration
  def change
    create_table :datasources do |t|
      t.references :project, index: true

      t.timestamps null: false
    end
    add_foreign_key :datasources, :projects
  end
end
