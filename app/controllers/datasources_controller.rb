class DatasourcesController < ApplicationController

  include ApplicationHelper

  before_action :authenticate_user!
  before_action :correct_user

  def destroy
    ds = Datasource.where(id: params[:id]).first
    ds.delete_associated_artifacts
    Datasource.find(params[:id]).destroy
    redirect_to project_path(params[:project_id])
  end

  private
    def correct_user
      @ds = current_user.projects.find_by(id: params[:project_id]).datasources.find_by(id: params[:id])
      redirect_to root_url if @ds.nil?
    end

end
