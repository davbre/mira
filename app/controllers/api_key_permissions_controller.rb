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
    @key = ApiKey.find(params[:api_key_id])
    project_ids = params[:api_key_permission][:projects]
    project_ids_ok? project_ids
    save_count = 0
    if (@key.user == current_user \
        && (project_ids == ["all"] || project_ids_ok?(project_ids)))
      if project_ids == ["all"]
        scope = 0 # global
      else
        scope = 1 # project
      # TODO table level permissions...worth it?
      # elsif table_id.to_i > 0
      #   scope = 2 # table
      end

      project_ids.each do |pid|
        @permission = @key.api_key_permissions.build(api_key_permission_params)
        @permission.permission_scope = scope
        @permission.project_id = pid.to_i if scope == 1
        save_count += 1 if @permission.save
      end
    end

    if save_count>0
      flash[:success] = save_count.to_s + " new API key permission(s) created."
      redirect_to user_api_key_api_key_permissions_url(current_user, @key)
    else
      flash[:error] = "API key permission(s) not saved"
      render 'new'
    end
  end

  #
  # def edit
  #   @key = ApiKey.find(params[:id])
  #   # TODO
  # end
  #
  #
  # def update
  #   # TODO
  # end
  #
  #
  # def destroy
  #   key = ApiKey.where(user: current_user.id, id: params[:id]).first
  #   if key.destroy
  #     flash[:success] = "API key deleted"
  #   else
  #     flash[:error] = "Failed to delete API key"
  #   end
  #   redirect_to user_api_keys_url(current_user)
  # end


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

    def project_ids_ok?(proj_id_array)
      return false if proj_id_array.class != Array
      user_proj_match = []
      proj_id_array.each do |p|
        user_proj_match.push current_user.projects.where(id: p.to_i).first
      end
      return false if user_proj_match.include? nil
      true
    end
end
