require 'load_dynamic_AR_class_with_scopes'

class ServerController < ApplicationController

  #before_filter :authenticate_user!
  
  def load_new_table
    load_dynamic_AR_class_with_scopes(params[:table_name])
    render :nothing => true # http://stackoverflow.com/a/12919687/1002140
  end

end