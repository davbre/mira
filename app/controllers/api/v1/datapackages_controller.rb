module Api
module V1


  class DatapackagesController < ApplicationController

    include ApplicationHelper

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      render json: datapackage
    end

  end


end
end
