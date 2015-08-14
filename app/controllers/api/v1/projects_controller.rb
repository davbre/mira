module Api
module V1

  class ProjectsController < ApplicationController

    def index
      paginate json: Project.all
	  end

    def show
      render json: Project.find(params[:id])
    end

  end

end
end