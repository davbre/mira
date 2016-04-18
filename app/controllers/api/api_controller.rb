class Api::ApiController < ActionController::Base



private

  # permission_scope: 0 => global, 1 => project
  # permission: 0 => read, 1 => write
  def key_authorize_read

    if db_key.present?
      global_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 0).first
      if global_permission.nil?
        project_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 1, project_id: params[:project_id]).first
      else
        project_permission = nil
      end
    end

    unless global_permission || project_permission
      head status: :unauthorized
      return false
    end
  end


  def key_authorize_write

    if db_key.present?
      global_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 0, permission: 2).first
      if global_permission.nil?
        project_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 1, permission: 2, project_id: params[:project_id]).first
      else
        project_permission = nil
      end
    end

    unless global_permission || project_permission
      head status: :unauthorized
      return false
    end
  end

  def db_key
    header_api_key = request.headers['X-Api-Key']
    ApiKey.where(token: header_api_key).first # should be unique on DB
  end
end
