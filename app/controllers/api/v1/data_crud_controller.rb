module Api
  module V1
    class DataCrudController < ActionController::Base

      include ApplicationHelper

      def create
        project = Project.find(params[:project_id])
        resource = get_resource(project,params[:table_ref])
        db_table = get_mira_ar_table("#{resource.db_table_name}")
        resource_fields = DatapackageResourceField.where(:datapackage_resource_id => resource.id)
        expected_field_names = resource_fields.map { |f| f[:name] }
        expected_field_types = resource_fields.map { |f| f[:ftype] }

        param_suff = "_val" # this is the suffix we expect (using a suffix for parameters to avoid any conflict with other variable names)
        valmap = params.select { |k,v| k.ends_with?  param_suff }
        actual_fields = {}
        valmap.each { |k,v| actual_fields[k.slice(0,k.length-param_suff.length).to_sym] = v }

        new_row = db_table.new( actual_fields )
        if new_row.save
          binding.pry
        else
          binding.pry
        end

        render json: {boom: "created!" }
      end


      def show
        project = Project.find(params[:project_id])
        resource = get_resource(project,params[:table_ref])
        db_table = get_mira_ar_table("#{resource.db_table_name}")
        row = db_table.find(params[:data_id])
        render json: row
      end


      def update
        render json: {boom: "updated!" }
      end


      def destroy
        render json: {boom: "deleted!" }
      end


      private
        def get_resource(project,table_ref)
          DatapackageResource.where(datapackage_id: project.datapackage.id,table_ref: "#{params[:table_ref]}").first
        end
    end
  end
end
