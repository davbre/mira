class ApiKeysController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper

  before_action :authenticate_user!
  before_action :correct_user#, only: [ :destroy, :edit, :update ]


  def index
    @keys = ApiKey.where(user_id: current_user.id).order(id: :desc).page params[:page] # kaminari
  end


  def show
    @key = ApiKey.find(params[:id])
  end


  def new
    @key = ApiKey.new
  end


  def create
    @key = current_user.api_keys.build(api_key_params)
    @key.token = generate_api_key
    if @key.save
      flash[:success] = "New API key created."
      redirect_to user_api_keys_url(current_user)
    else
      render 'new'
    end
  end


  def edit
    @key = ApiKey.find(params[:id])
    # @key.token = generate_api_key
    # @key.save
  end


  def update
    @key = ApiKey.find(params[:id])
    if @key.update_attributes(api_key_params)
      flash[:success] = "API key updated"
      redirect_to user_api_keys_url(@user)
    else
      render 'edit'
    end
  end


  def destroy
    key = ApiKey.where(user: current_user.id, id: params[:id]).first
    if key.destroy
      flash[:success] = "API key deleted"
    else
      flash[:error] = "Failed to delete API key"
    end
    redirect_to user_api_keys_url(current_user)
  end


  def gen_new_key
    @key = ApiKey.find(params[:id])
    @key.token = generate_api_key
    if @key.save
      flash[:success] = "New API key created: " + @key.token
    else
      flash[:error] = "Failed to generate new API key!"
    end
    redirect_to user_api_keys_url(current_user)
  end


  def index_project
    select_str = "api_key_permissions.id,api_key_permissions.permission"
    select_str += ",api_key_permissions.permission_scope,api_keys.description,api_keys.token"
    @proj_keys_info = ApiKeyPermission.where(project_id: [nil, params[:project_id]]).joins(:api_key).select(select_str).order(id: :desc).page params[:page]
  end


  private


    # Rails strong parameters
    def api_key_params
      params.require(:api_key).permit(:description)
    end

    def correct_user
      @user = current_user
      redirect_to root_url if params[:user_id] != current_user.id.to_s
    end

    def generate_api_key
      loop do
        token = SecureRandom.hex(12)
        break token unless ApiKey.exists?(token: token)
      end
    end

end
