module Api
module V1


  class DatapackageResourceFieldsController < ApplicationController

    include ApplicationHelper

    def index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      resource_fields = DatapackageResourceField.where(datapackage_resource_id: datapackage_resource.id).order(:order)
      response = resource_fields.as_json(:only => [:name, :ftype, :order])
      render json: response
    end

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      resource_field = DatapackageResourceField.where(datapackage_resource_id: datapackage_resource.id,name: params[:col_ref]).order(:order).first
      response = resource_field.as_json(:only => [:name, :ftype, :order])
      render json: response
    end
  end


end
end
