class BigIntegerToDatapackageResourceFields < ActiveRecord::Migration
  def change
    add_column :datapackage_resource_fields, :big_integer, :boolean
  end
end
