class AddAttachmentFileToDatapackages < ActiveRecord::Migration
  def self.up
    change_table :datapackages do |t|
      t.attachment :datapackage
    end
  end

  def self.down
    remove_attachment :datapackages, :datapackage
  end
end
