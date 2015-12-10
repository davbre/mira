module Api
module V1


  class DatasourcesController < ApplicationController

    include ApplicationHelper

    def index
      datasources = Project.find(params[:id]).datasources
      response = datasources.as_json(:except => datasource_exclude_fields)
      paginate json: response
    end


    def show
      # datasource = Project.find(params[:id]).datasources.where(table_ref: "#{params[:table_ref]}" ).first
      # binding.pry
      project = Project.find(params[:id])
      resource = DatapackageResource.where(datapackage_id: project.datapackage.id,table_ref: "#{params[:table_ref]}").first
      render_hash = resource.as_json
      ar_table = get_mira_ar_table(resource.db_table_name)
      render_hash[:row_count] = ar_table.count
      response = render_hash.as_json(:except => datasource_exclude_fields)
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
