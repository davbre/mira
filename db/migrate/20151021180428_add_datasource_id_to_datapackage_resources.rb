class AddDatasourceIdToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :datasource_id, :integer
  end
end
