module Api
module V1


  class DatasourcesController < Api::ApiController

    include ApplicationHelper

    before_action :key_authorize_read

    def index
      datasources = Project.find(params[:id]).datasources
      response = datasources.as_json(:except => datasource_exclude_fields)
      paginate json: response
    end


    def show
      datasource = Project.find(params[:id]).datasources.where(datafile_file_name: params[:table_ref] + ".csv").first
      response = datasource.as_json(:except => datasource_exclude_fields)
      render json: response
    end


    private

      def datasource_exclude_fields
        exclude = user_signed_in? ? [] : ["db_table_name"]
        exclude
      end
  end


end
end
