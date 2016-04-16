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

  #
  # def show
  #   @user = current_user
  #   @key = ApiKey.find(params[:id])
  # end
  #
  #
  # def new
  #   @key = ApiKey.new
  #   @user = current_user
  # end
  #
  #
  # def create
  #   @key = current_user.api_keys.build(api_key_params)
  #   @key.token = generate_api_key
  #   if @key.save
  #     flash[:success] = "New API key created."
  #     redirect_to user_api_key_url(current_user, @key)
  #   else
  #     render 'new'
  #   end
  # end
  #
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
      params.require(:api_key_permission).permit(:scope, :permission)
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

end
