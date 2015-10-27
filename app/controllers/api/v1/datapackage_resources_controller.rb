module Api
module V1


  class DatapackageResourcesController < ApplicationController

    include ApplicationHelper

    def index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resources = datapackage.datapackage_resources
      paginate json: datapackage_resources
    end

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      render json: datapackage_resource
    end

  end


end
end
