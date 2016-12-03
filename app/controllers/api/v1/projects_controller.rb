module Api
module V1

  class ProjectsController < ActionController::Base

    def index
      header_api_key = request.headers['X-Api-Key']
      api_key = ApiKey.where(token: header_api_key).first
      # if the API key sent is a global key OR if no global key exists, then send all projects
      if key_has_global_permission?(api_key) || !global_permission_exists?
        resp = Project.all
      # if a global permission exists (but is not sent), then only display the projects relating to that key
      elsif global_permission_exists?
        if api_key.nil?
          resp =  not_authorized_response
        else
          key_project_ids = get_key_project_ids(api_key)
          resp = Project.where(project_id: key_project_ids)
          paginate json: resp
        end
      else
        resp = { message: "No projects to list" }
      end
      # reaches here if nothing to paginate or error
      render json: resp

	  end


    def show
      header_api_key = request.headers['X-Api-Key']
      api_key = ApiKey.where(token: header_api_key).first
      key_project_ids = (api_key.present?) ? get_key_project_ids(api_key) : []
      if key_has_global_permission?(api_key) || !global_permission_exists? \
           || key_project_ids.include?(params[:id].to_i)
        resp = Project.find(params[:id])
      else
        resp = not_authorized_response
      end
      render json: resp
    end


    private

      def not_authorized_response
        {errors: [ code: 401, message: "Not authorized." ]}
      end

      def key_has_global_permission?(api_key)
        return false if api_key.nil?
        ApiKeyPermission.where(api_key_id: api_key.id, permission_scope: 0).present?
      end

      def global_permission_exists?
        ApiKeyPermission.where(permission_scope: 0).present?
      end

      def get_key_project_ids(api_key)
        ApiKeyPermission.where(api_key_id: api_key.id, permission_scope: 1).map { |p| p.project_id }
      end
  end

end
end
