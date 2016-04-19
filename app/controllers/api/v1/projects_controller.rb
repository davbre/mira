module Api
module V1

  class ProjectsController < Api::ApiController

    #before_action :key_authorize_read

    def index
      paginate json: Project.all
	  end

    def show
      render json: Project.find(params[:id])
    end

  end

end
end
