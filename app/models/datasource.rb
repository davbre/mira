class Datasource < ActiveRecord::Base

  belongs_to :project
  belongs_to :datapackage_resource
  validates :project_id, presence: true

  has_attached_file :datafile,
    :path => ":rails_root/" + Rails.configuration.x.upload_path + "/project_:proj_id/:filename",
    :url  => "/uploads/project_:proj_id/:filename",
    :restricted_characters => /@/ # paperclip automatically cleans up names apparently, replacing
                                 # characters with underscores. Using this option to negate this
                                 # behaviour. See http://stackoverflow.com/questions/7328423/does-paperclip-automatically-clean-up-filenames

  # validates_attachment :datafile, :content_type => /\Atext\/csv/
  validates_attachment :datafile, content_type: { :content_type => [/\Atext\//, "application/json"] }
  validates_attachment_file_name :datafile, :matches => [/csv\Z/]

  validate :validate_filename_unique, on: :create

  process_in_background :datafile # delayed_paperclip

  enum import_status: [ :ok, :note, :warning, :error ]

  before_save :set_logfile_path
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

  def set_logfile_path
    self.logfile_path = Project.find(self.project_id).job_log_path + self.datafile_file_name + ".log"
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

    def delete_associated_artifacts
      # There is no need to delete the uploaded file as this will occur on delete anyway.
      # delete_upload
      delete_logfile
    end

    def delete_logfile
      if self.logfile_path.present? && self.logfile_path.length>8 && logfile_path.upcase.end_with?(".LOG")
        File.delete(self.logfile_path) if File.exist?(self.logfile_path)
      end
    end

    def delete_upload
      upload_file_name = Datasource.find(ds.id).datafile_file_name
      upload = self.datapackage.project.upload_path + upload_file_name
      File.delete(upload) if File.exist?(upload)
    end
end
