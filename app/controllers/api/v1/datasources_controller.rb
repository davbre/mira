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


    def column_index
      datasource = Project.find(params[:id]).datasources.where(table_ref: "#{params[:table_ref]}" ).first
      ar_object = get_mira_ar_table(datasource.db_table_name)
      render_hash = {}
      ar_object.columns_hash.each { |a| render_hash[a[1].name] = a[1].sql_type }
      render json: render_hash
    end


    def column_show
      datasource = Project.find(params[:id]).datasources.where(table_ref: "#{params[:table_ref]}" ).first
      ar_object_col = get_mira_ar_table(datasource.db_table_name).columns_hash[params[:col_ref]]
      render_hash = { "name" => ar_object_col.name, "type" => ar_object_col.sql_type}
      render json: render_hash
    end

    private

      def datasource_exclude_fields
        exclude = user_signed_in? ? [] : ["db_table_name"]
        exclude
      end
  end


end
end
