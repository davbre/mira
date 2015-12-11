module Api
module V1


  class DatapackageResourceFieldsController < ApplicationController

    include ApplicationHelper

    def index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      resource_fields = DatapackageResourceField.where(datapackage_resource_id: datapackage_resource.id).order(:order)
      response_array = []
      resource_fields.each do |fld|
        full_field_response = rename_ftype(fld.attributes)
        trimmed_field_response = full_field_response.select {|k,v| keep_keys.include? k }
        response_array << trimmed_field_response
      end
      response = response_array.as_json
      render json: response
    end

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      resource_field = DatapackageResourceField.where(datapackage_resource_id: datapackage_resource.id,name: params[:col_ref]).order(:order).first
      response = rename_ftype(resource_field.attributes)
      response = resource_field.as_json(:only => keep_keys)
      render json: response
    end

    private

      def rename_ftype(resp_hash)
        resp_hash["type"] = resp_hash.delete "ftype"
        resp_hash
      end

      def keep_keys
        ["name", "type", "order", "add_index", "big_integer", "format"]
      end
  end


end
end
