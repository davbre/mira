module Api
module V1


  class DatasourcesController < ApplicationController

    include ApplicationHelper

    def index
      paginate json: Project.find(params[:id]).datasources
    end


    def show
      datasource = Project.find(params[:id]).datasources.where(table_ref: "#{params[:table_ref]}" ).first
      ar_table = get_mira_ar_table(datasource.db_table_name)
      numrows = ar_table.count
      render_hash = datasource.attributes
      render_hash[:row_count] = numrows
      render json: render_hash
    end


    def show_columns
      datasource = Project.find(params[:id]).datasources.where(table_ref: "#{params[:table_ref]}" ).first
      ar_object = get_mira_ar_table(datasource.db_table_name)
      render_hash = {}
      ar_object.columns_hash.each { |a| render_hash[a[1].name] = a[1].sql_type }
      render json: render_hash
    end
  end


end
end