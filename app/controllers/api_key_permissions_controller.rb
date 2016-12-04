class ApiKeyPermissionsController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper

  before_action :authenticate_user!
  before_action :correct_user #, only: [ :destroy, :edit, :update ]


  def index
    @permissions = ApiKeyPermission.where(api_key_id: @key.id).order(id: :desc).page params[:page]
  end

  def new
    @permission = ApiKeyPermission.new
  end

  def create
    @flash_notice, @flash_success, @flash_error = [], [], []
    @key = ApiKey.find(params[:api_key_id])
    project_ids = params[:api_key_permission][:projects]
    apply_permission = params["api_key_permission"]["permission"]

    check_projects project_ids

    if @flash_error == [] && @key.user == current_user
      scope = project_ids == ["all"] ? 0 : 1  # global or project scope

      if scope == 1 && ApiKeyPermission.where(api_key_id: params[:api_key_id],permission_scope: 0).where("permission >= ?", ApiKeyPermission.permissions[apply_permission]).present?
        @flash_error << "Project level permissions not added as this API key already has a global " + apply_permission + " permission applied"
      else
        project_ids.each do |pid|
          scope_pid = scope == 0 ? nil : pid
          proj_perm = ApiKeyPermission.where(api_key_id: params[:api_key_id],project_id: scope_pid,permission_scope: scope).first

          proj_name = scope == 0 ? "all projects" : Project.find(pid).name

          # Permission already exists
          if proj_perm.present?
            # If permission already exists for this project and it is the same just update flash notice
            if proj_perm.permission == apply_permission
              @flash_notice << proj_perm.permission + " permission already exists for project: " + proj_name
            else
              if proj_perm.update(permission: apply_permission)
                @flash_success << "Permission updated for project (now " + proj_perm.permission + "): " + proj_name
              else
                @flash_error << "Failed to add " + proj_perm.permission + " permission for project: " + proj_name
              end
            end
          else
            # New permission
            @permission = @key.api_key_permissions.build(api_key_permission_params)
            @permission.permission_scope = scope
            @permission.project_id = pid.to_i if scope == 1
            if @permission.save
              @flash_success << "Saved " + apply_permission + " for project: " + proj_name
              # If applying a global permission, then delete project level permissions that already exist
              remove_project_level_permissions(apply_permission) if scope == 0
            else
              flash_error << " Failed to save " + apply_permission+ " for project: " + proj_name
            end
          end
        end
      end

    end

    flash[:error] = @flash_error.join("  ---  ") if @flash_error.present?
    flash[:notice] = @flash_notice.join("  ---  ") if @flash_notice.present?
    flash[:success] = @flash_success.join("  ---  ") if @flash_success.present?

    redirect_to user_api_key_api_key_permissions_url(current_user, @key)

  end


  def destroy
    key = ApiKey.where(user: current_user.id, id: params[:api_key_id]).first
    key_permission = ApiKeyPermission.where(id: params[:id], api_key_id: params[:api_key_id]).first

    if key.user_id == current_user.id && key_permission.destroy
      flash[:success] = "API key permission deleted"
    else
      flash[:error] = "Failed to delete API key permission"
    end

    redirect_to user_api_key_api_key_permissions_url(current_user,key)
  end


  private


    # Rails strong parameters
    def api_key_permission_params
      params.require(:api_key_permission).permit(:project_id, :permission)
    end

    def correct_user
      if params[:user_id] != current_user.id.to_s
        redirect_to root_url
      else
        @user = current_user
        @key = ApiKey.find(params[:api_key_id])
      end
    end

    def generate_api_key
      loop do
        token = SecureRandom.hex(12)
        break token unless ApiKey.exists?(token: token)
      end
    end

    def check_projects(project_ids)
      if (project_ids.length > 1) && (project_ids.include? "all")
        @flash_error << "You cannot select 'All projects' and individual projects!"
      end

      if !project_ids_ok?(project_ids)
        @flash_error << "Could not create/update permissions!"
      end
    end

    def project_ids_ok?(proj_id_array)
      return false if proj_id_array.class != Array
      user_proj_match = []
      proj_id_array.each do |p|
        user_proj_match.push current_user.projects.where(id: p.to_i).first
      end
      return false if (proj_id_array != ["all"]) && (user_proj_match.include? nil)
      true
    end

    def remove_project_level_permissions(perm)
      proj_lev_perms = ApiKeyPermission.where(api_key_id: params[:api_key_id],permission_scope: 1)
      if proj_lev_perms.present?
        if proj_lev_perms.destroy_all
          @flash_notice << "Removed all project level " + perm + " permissions (not needed with new global permission)"
        else
          @flash_error << "Failed to remove project level " + perm + " (which are not now needed with global permission)"
        end
      end
    end
end
