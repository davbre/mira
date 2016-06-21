module DataAccessHelper

  private
  def key_authorize_read
    # If no project key permissions set then allow read access. Otherwise check for valid permission.
    if no_project_permissions?
      global_permission = "ok"
    elsif db_key.present?
      global_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 0).first
      if global_permission.nil?
        project_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 1, project_id: params[:id]).first
      else
        project_permission = nil
      end
    end

    unless global_permission || project_permission
      render json: resp401("for read access"), status: 401
    end
  end


  def key_authorize_write
    if db_key.present?
      global_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 0, permission: 1).first
      if global_permission.nil?
        project_permission = ApiKeyPermission.where(api_key_id: db_key.id, permission_scope: 1, permission: 1, project_id: params[:id]).first
      else
        project_permission = nil
      end
    end

    unless global_permission || project_permission
      render json: resp401("for write access"), status: 401
    end
  end


  def no_project_permissions?
    # Check no global API key and no project specific key. If none => we will later allow read access
    ApiKeyPermission.where(project_id: nil,permission_scope: 0).empty? && ApiKeyPermission.where(project_id: params[:id]).empty?
  end


  def db_key
    header_api_key = request.headers['X-Api-Key']
    ApiKey.where(token: header_api_key).first # should be unique on DB
  end

  def resp401(extra)
    message = "No valid API key provided."
    message = message.chop + " " + extra + "." if extra.present?
    {errors: [ code: 401, message: message]}
  end

end
