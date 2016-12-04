class DatapackagesController < ApplicationController

  include ApplicationHelper
  include DataAccessHelper

  before_action :key_authorize_read, only: [:show]

  def show
    project = Project.find(params[:project_id])
    @datapackage = project.datapackage
    send_file @datapackage.datapackage.path, :type => @datapackage.datapackage_content_type, :disposition => 'inline'
  end

  # to destroy a datapackage, we just destroy the project (because the project is
  # pretty much defined by the datapackage), so no need for action here

end
