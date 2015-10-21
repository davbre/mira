class Project < ActiveRecord::Base

  belongs_to :user
  has_one :datapackage, dependent: :destroy
  has_many :datasources, dependent: :destroy

  validates :name,
            presence: true,
            length: { maximum: 64 },
            uniqueness: { case_sensitive: false }
  validates :user_id, presence: true

  def job_log_path
    Rails.configuration.x.job_log_path + "/project_" +  self.id.to_s + "/"
  end

  def upload_path
    Rails.configuration.x.upload_path + "/project_" +  self.id.to_s + "/"
  end
end
