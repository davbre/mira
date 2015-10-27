class AddQuoteCharacterToDatapackageResources < ActiveRecord::Migration
  def change
    add_column :datapackage_resources, :quote_character, :text
  end
end
