class DatasourcesController < ApplicationController

  include ApplicationHelper
  include DataAccessHelper

  before_action :authenticate_user!, only: [:destroy]
  before_action :correct_user, only: [:destroy]

  before_action :key_authorize_read, only: [:show, :index]
  # before_action :key_authorize_write, only: [:destroy, :update]

  def show
    @ds = Datasource.find(params[:id])
    send_file @ds.datafile.path, :type => @ds.datafile_content_type #, :disposition => 'inline'
  end

  def index
    @proj = Project.find(params[:project_id])
    @dss = @proj.datasources.page params[:page]
  end

  def destroy
    @proj = Project.find(params[:project_id])
    @ds = Datasource.find(params[:id])
    @dpr = DatapackageResource.find(@ds.datapackage_resource_id)
    # delete_associated_artifacts
    num_rows_deleted = remove_datasource_rows_from_db_table
    flash[:notice] = "Deleted " + num_rows_deleted.to_s + " rows from the corresponding database table."
    ds_name = @ds.datafile_file_name
    if Datasource.find(params[:id]).destroy
      flash[:notice].prepend(ds_name + " successfully deleted. ")
    end
    redirect_to project_datapackage_datapackage_resource_path(@proj,@dpr)#project_path(params[:project_id])
  end

  private

    def correct_user
      @ds = current_user.projects.find_by(id: params[:project_id]).datasources.find_by(id: params[:id])
      redirect_to root_url if @ds.nil?
    end

    def remove_datasource_rows_from_db_table
      dpr = DatapackageResource.find(@ds.datapackage_resource_id)
      db_table = get_mira_ar_table(dpr.db_table_name)
      num_rows_deleted = db_table.where(mira_source_type: "csv", mira_source_id: @ds.id).delete_all
    end
end
