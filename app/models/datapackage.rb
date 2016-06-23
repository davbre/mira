class Datapackage < ActiveRecord::Base
  belongs_to :project
  has_many  :datapackage_resources, dependent: :destroy
  validates :project_id, presence: true

  has_attached_file :datapackage,
    :path => ":rails_root/public/uploads/project_:proj_id/:filename",
    :url  => "/uploads/project_:proj_id/:filename"

  validates_attachment :datapackage, content_type: { :content_type => ["text/plain", "application/json"] }
  validates_attachment_file_name :datapackage, :matches => [/datapackage.json\Z/]

  private

    # Use an interpolation to get project_id into the path
    # https://github.com/thoughtbot/paperclip/wiki/Interpolations
    #http://stackoverflow.com/questions/9173920/paperclip-custom-path-with-id-belongs-to
    Paperclip.interpolates :proj_id do |attachment, style|
      attachment.instance.project_id
    end

end
