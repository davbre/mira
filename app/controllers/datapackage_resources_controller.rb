class DatapackageResourcesController < ApplicationController

  include ApplicationHelper

  before_action :authenticate_user!
  # before_action :correct_user, only: [:destroy]

  def show
    @project = Project.find(params[:project_id])
    @dpr = DatapackageResource.find(params[:id])
    @dpr_ds = Datasource.where(datapackage_resource_id: @dpr.id).order(id: :desc).page params[:page] # kaminari
    db_table = get_mira_ar_table(@dpr.db_table_name)
    @apikey_ids = db_table.where(mira_source_type: "key").uniq.pluck(:mira_source_id)
    @fields = DatapackageResourceField.where(datapackage_resource_id: @dpr.id).order(:order)
    @tableUrl = request.base_url + "/api/projects/" + @project.id.to_s + "/tables/" + @dpr.table_ref + "/"
  end


  def delete_apikey_rows
    @proj = Project.find(params[:project_id])
    @dpr = DatapackageResource.find(params[:id])
    db_table = get_mira_ar_table(@dpr.db_table_name)
    num_rows_deleted = db_table.where(
                         mira_source_type: "key",
                         mira_source_id: params[:api_key_id]).delete_all
    flash[:notice] = "Deleted " + num_rows_deleted.to_s + " rows from the corresponding database table."
    redirect_to project_datapackage_datapackage_resource_path(@proj,@dpr)
  end


  def show_orig
    # /projects/:project_id/datapackage/datapackage_resources/:id
    # The aim is to show the datapackage resource (which gives the metadata of those files
    # that CAN be uploaded), and alongside this the actual files that have been uploaded
    @project = Project.find(params[:project_id])
    @dpr = DatapackageResource.find(params[:id])
    @dpr_ds = Datasource.where(datapackage_resource_id: @dpr.id)
    # get the unique API key IDs in the table
    db_table = get_mira_ar_table(@dpr.db_table_name)
    key_ids = db_table.uniq.pluck(:mira_source_id)
  end

  # def destroy
  #   ds = Datasource.where(id: params[:id]).first
  #   dp_res = DatapackageResource.where(datasource_id: ds.id).first
  #   dp_res.delete_associated_artifacts
  #   dp_res.clear_db_table
  #   Datasource.find(params[:id]).destroy
  #   redirect_to project_path(params[:project_id])
  # end

  private
    def correct_user
      @ds = current_user.projects.find_by(id: params[:project_id]).datasources.find_by(id: params[:id])
      redirect_to root_url if @ds.nil?
    end

end
