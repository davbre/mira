class ApiKey < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true    # using user_id here does not enforce that user actually exists. Using user does.
  validates :token, presence: true, length: { is: 24 }
end
