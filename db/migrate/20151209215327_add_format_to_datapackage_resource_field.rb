class AddFormatToDatapackageResourceField < ActiveRecord::Migration
  def change
    add_column :datapackage_resource_fields, :format, :text
  end
end
