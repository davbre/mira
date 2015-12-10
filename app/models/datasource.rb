class Datasource < ActiveRecord::Base

  belongs_to :project
  has_one :datapackage_resource
  validates :project_id, presence: true

  has_attached_file :datafile,
    :path => ":rails_root/public/uploads/project_:proj_id/:filename",
    :url  => "/uploads/project_:proj_id/:filename"

  # validates_attachment :datafile, :content_type => /\Atext\/csv/
  validates_attachment :datafile, content_type: { :content_type => [/\Atext\//, "application/json"] }
  validates_attachment_file_name :datafile, :matches => [/csv\Z/, /datapackage.*\.json/]

  process_in_background :datafile # delayed_paperclip

  enum import_status: [ :ok, :note, :warning, :error ]

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

end
