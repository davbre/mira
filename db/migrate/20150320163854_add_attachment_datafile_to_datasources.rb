class AddAttachmentDatafileToDatasources < ActiveRecord::Migration
  def self.up
    change_table :datasources do |t|
      t.attachment :datafile
    end
  end

  def self.down
    remove_attachment :datasources, :datafile
  end
end
