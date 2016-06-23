class Datasource < ActiveRecord::Base

  belongs_to :project
  belongs_to :datapackage_resource
  validates :project_id, presence: true

  has_attached_file :datafile,
    :path => ":rails_root/project_files/uploads/project_:proj_id/:filename",
    :url  => "/uploads/project_:proj_id/:filename"

  # validates_attachment :datafile, :content_type => /\Atext\/csv/
  validates_attachment :datafile, content_type: { :content_type => [/\Atext\//, "application/json"] }
  validates_attachment_file_name :datafile, :matches => [/csv\Z/]

  validate :validate_filename_unique, on: :create

  process_in_background :datafile # delayed_paperclip

  enum import_status: [ :ok, :note, :warning, :error ]

  before_destroy :retain_file_name
  after_destroy :delete_associated_artifacts

  # Some helper methods, useful for linking to log file
  def basename
    File.basename(self.datafile_file_name, ".*" )
  end

  def full_upload_path
    File.dirname(self.datafile.path)
  end

  def upload_path
    full_upload_path[/(?=\/datafiles).*/]
  end

  def logfile
    "upload_" + self.basename + ".log"
  end

  private

    # Use an interpolation to get project_id into the path
    # https://github.com/thoughtbot/paperclip/wiki/Interpolations
    #http://stackoverflow.com/questions/9173920/paperclip-custom-path-with-id-belongs-to
    Paperclip.interpolates :proj_name do |attachment, style|
      Project.find(attachment.instance.project_id).name
    end

    Paperclip.interpolates :proj_id do |attachment, style|
      attachment.instance.project_id
    end

    def validate_filename_unique
      if Datasource.where(project_id: self.project_id, datafile_file_name: self.datafile_file_name).length > 0
        errors.add(:datasource, "A file of this name has already been uploaded to this project!")
      end
    end

    def retain_file_name
      @ds_filename = self.datafile_file_name
    end

    def delete_associated_artifacts
      # delete_log
      # delete_upload
      binding.pry
    end

    def delete_log
      proj_log_path = Rails.configuration.x.job_log_path + "/project_" +  self.project_id.to_s + "/"
      log_file_name = self.datafile_file_name + ".log"
      log = self.datapackage.project.job_log_path + log_file_name
      File.delete(log) if File.exist?(log)
    end

    def delete_upload
      upload_file_name = Datasource.find(ds.id).datafile_file_name
      upload = self.datapackage.project.upload_path + upload_file_name
      File.delete(upload) if File.exist?(upload)
    end
end
