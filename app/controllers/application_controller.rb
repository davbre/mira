class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  # DBR going to turn this off as want to POST uploads via curl
  # and only currently open to an admin user
  # protect_from_forgery with: :exception

end
