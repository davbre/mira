class AddDescriptionToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :description, :text
  end
end
