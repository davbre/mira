class DatasourcesController < ApplicationController

  include ApplicationHelper

  before_action :authenticate_user!
  before_action :correct_user

  def destroy
    ds = Datasource.where(id: params[:id]).first
    ds.delete_associated_artefacts
    associated_datapackage_id = ds.datapackage_id
    # check to see what other files are associated with the same datapackage. If
    # this is the only file remaining, then delete the datapackage also
    Datasource.find(params[:id]).destroy
    remaining_related_datasources = Datasource.where(datapackage_id: associated_datapackage_id)

    if remaining_related_datasources.empty?
      lonely_datapackage = Datasource.find(ds.datapackage_id)
      lonely_datapackage.delete_associated_artefacts
      lonely_datapackage.destroy
    end
    
    redirect_to project_path(params[:project_id])
  end

  private
    def correct_user
      @ds = current_user.projects.find_by(id: params[:project_id]).datasources.find_by(id: params[:id])
      redirect_to root_url if @ds.nil?
    end

#   def destroy
#     User.find(params[:id]).destroy
#     flash[:success] = "User deleted"
#     redirect_to users_url
#   end
end
