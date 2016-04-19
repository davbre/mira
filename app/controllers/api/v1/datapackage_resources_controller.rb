module Api
module V1


  class DatapackageResourcesController < Api::ApiController

    include ApplicationHelper

    before_action :key_authorize_read

    def index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resources = datapackage.present? ? datapackage.datapackage_resources : []
      response = []
      datapackage_resources.each do |res|
        resource_with_url = add_public_url_to_resource(res)
        response << resource_with_url.except("db_table_name")
      end
      paginate json: response
    end

    def show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = datapackage.datapackage_resources.where(table_ref: params[:table_ref]).first
      resource_with_url = add_public_url_to_resource(datapackage_resource)
      render json: resource_with_url.except("db_table_name")
    end

    def column_index
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = DatapackageResource.where(datapackage_id: datapackage.id, table_ref: params[:table_ref]).first
      ar_object = get_mira_ar_table(datapackage_resource.db_table_name)
      render_hash = {}
      ar_object.columns_hash.each { |a| render_hash[a[1].name] = a[1].sql_type }
      render json: render_hash
    end

    def column_show
      project = Project.find(params[:id])
      datapackage = Datapackage.where(project_id: project.id).first
      datapackage_resource = DatapackageResource.where(datapackage_id: datapackage.id, table_ref: params[:table_ref]).first
      ar_object_col = get_mira_ar_table(datapackage_resource.db_table_name).columns_hash[params[:col_ref]]
      render_hash = { "name" => ar_object_col.name, "type" => ar_object_col.sql_type}
      render json: render_hash
    end

    private

      def add_public_url_to_resource(res)
        res_as_hash = res.attributes

        if res.datasource_id.present?
          datasource = Datasource.find(res.datasource_id)
          upload_public_url = datasource.public_url
          import_status = datasource.import_status
        else
          upload_public_url = ""
          import_status = nil
        end
        res_as_hash[:public_url] = upload_public_url
        res_as_hash[:import_status] = import_status
        res_as_hash
      end

  end


end
end
