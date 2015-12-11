class DatapackageResource < ActiveRecord::Base
  belongs_to :datapackage
  has_many :datapackage_resource_fields
  belongs_to :datasource  # this is not required. Only set when corresponding file
                       # has been uploaded
  validates :datapackage_id, presence: true
  validates :path, presence: true
  validates :delimiter, presence: true
  validates :quote_character, presence: true
  validates :table_ref, presence: true, uniqueness: { scope: :datapackage,
                                        message: "table_ref must be unique within a datapackage!" }

  def delete_associated_artifacts
    if self.datasource_id.present?
      delete_log
      delete_upload
      self.datasource_id = nil
      self.save
    end
  end

  def delete_db_table
    table = self.db_table_name
    if ActiveRecord::Base.connection.table_exists? table
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  def clear_db_table
    ar_table = Mira::Application.const_get(self.db_table_name.capitalize.to_sym)
    if ActiveRecord::Base.connection.table_exists? ar_table
      ar_table.delete_all
    end
  end

  def delete_log
    log_file_name = Datasource.find(self.datasource_id).datafile_file_name + ".log"
    log = self.datapackage.project.job_log_path + log_file_name
    File.delete(log) if File.exist?(log)
  end

  def delete_upload
    upload_file_name = Datasource.find(self.datasource_id).datafile_file_name
    upload = self.datapackage.project.upload_path + upload_file_name
    File.delete(upload) if File.exist?(upload)
  end

end
