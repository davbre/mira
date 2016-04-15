class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # DBR: removed from above (only want admin user(s): :registerable,

  has_many :projects
  has_many :api_keys
end
