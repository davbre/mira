class Project < ActiveRecord::Base

  belongs_to :user
  has_many :datasources, dependent: :destroy

  validates :name,
            presence: true,
            length: { maximum: 64 },
            uniqueness: { case_sensitive: false }
  validates :user_id, presence: true
end