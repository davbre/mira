module Api
module V1


  class DatapackageResourcesController < ActionController::Base

    include ApplicationHelper
    include DataAccessHelper

    before_action :key_authorize_read

    def index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resources = datapackage.present? ? datapackage.datapackage_resources : []
      paginate json: datapackage_resources, except: [:db_table_name]
    end

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      render json: datapackage_resource, except: [:db_table_name]
    end

    def column_index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = DatapackageResource.where(datapackage_id: datapackage.id, table_ref: params[:table_ref]).first
      ar_object = get_mira_ar_table(datapackage_resource.db_table_name)
      render_hash = {}
      ar_object.columns_hash.each { |a| render_hash[a[1].name] = a[1].sql_type }
      render json: render_hash
    end

    def column_show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = DatapackageResource.where(datapackage_id: datapackage.id, table_ref: params[:table_ref]).first
      ar_object_col = get_mira_ar_table(datapackage_resource.db_table_name).columns_hash[params[:col_ref]]
      render_hash = { "name" => ar_object_col.name, "type" => ar_object_col.sql_type}
      render json: render_hash
    end


  end


end
end
