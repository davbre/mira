class DatasourcesController < ApplicationController

  include ApplicationHelper

  before_action :authenticate_user!
  before_action :correct_user

  def destroy
    ds = Datasource.where(id: params[:id]).first
    dp_res = DatapackageResource.where(datasource_id: ds.id).first
    dp_res.delete_associated_artifacts
    dp_res.clear_db_table
    Datasource.find(params[:id]).destroy
    redirect_to project_path(params[:project_id])
  end

  private
    def correct_user
      @ds = current_user.projects.find_by(id: params[:project_id]).datasources.find_by(id: params[:id])
      redirect_to root_url if @ds.nil?
    end

end
