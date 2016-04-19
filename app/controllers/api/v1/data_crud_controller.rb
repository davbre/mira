module Api
  module V1
    class DataCrudController < Api::ApiController

      include ApplicationHelper

      before_action :key_authorize_read, only: [ :show ]
      before_action :key_authorize_write, only: [:create, :destroy, :update]

      # http_basic_authenticate_with name: "admin", password: "pass"

      @@param_suffix = "_val"  # this is the suffix we expect to see in incoming urls (using a suffix for parameters to avoid any conflict with other variable names)

      def create
        db_table = get_db_table(params[:id],params[:table_ref])
        field_values = get_field_values(params)

        @new_row = db_table.new(field_values)

        if @new_row.save
          response = @new_row
        else
          response = { error: @new_row.errors.messages }
        end
        render json: response

      end


      def show
        binding.pry
        db_table = get_db_table(params[:id],params[:table_ref])
        row = db_table.find(params[:data_id])
        render json: row
      end


      def update
        db_table = get_db_table(params[:id],params[:table_ref])
        field_values = get_field_values(params)

        @row = db_table.find(params[:data_id])
        if @row.update(field_values)
          response = @row
        else
          response = { error: @row.errors.messages }
        end
        render json: response
      end


      def destroy
        db_table_hash = get_db_table_info(params[:id],params[:table_ref])
        db_table = db_table_hash[:db_table]
        @row = db_table.where(id: params[:data_id]).first
        if @row.present? && @row.destroy
          response = { meta: {
                         id: db_table_hash[:project].id,
                         table: db_table_hash[:resource].db_table_name,
                         table_id: params[:data_id],
                         status: "deleted"
                     }}
        else
          response = { error: 404 }
        end
        render json: response, status: :not_found
      end


      private

        def get_db_table(project_id,table_ref)
          project = Project.find(project_id)
          resource = DatapackageResource.where(datapackage_id: project.datapackage.id,table_ref: table_ref).first
          db_table = get_mira_ar_table("#{resource.db_table_name}")
        end

        def get_db_table_info(project_id,table_ref)
          project = Project.find(project_id)
          resource = DatapackageResource.where(datapackage_id: project.datapackage.id,table_ref: table_ref).first
          db_table = get_mira_ar_table("#{resource.db_table_name}")
          { project: project, resource: resource, db_table: db_table }
        end

        def get_field_values(params)
          valmap = params.select { |k,v| k.ends_with? @@param_suffix }
          actual_fields = {}
          valmap.each { |k,v| actual_fields[k.slice(0,k.length-@@param_suffix.length).to_sym] = v }
          actual_fields
        end

    end
  end
end
