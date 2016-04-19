module Api
module V1


  class DatapackagesController < Api::ApiController

    include ApplicationHelper

    before_action :key_authorize_read

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      render json: datapackage
    end

  end


end
end
