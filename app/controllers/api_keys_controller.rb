class ApiKeysController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper

  before_action :authenticate_user!
  before_action :correct_user#, only: [ :destroy, :edit, :update ]


  def index
    @user = current_user
    @keys = ApiKey.where(user_id: current_user.id).order(id: :desc).page params[:page] # kaminari
  end


  def show
    @user = current_user
  end


  def new
    @key = ApiKey.new
    @user = current_user
  end


  def create
    @key = current_user.api_keys.build(api_key_params)
    @key.token = generate_api_key
    if @key.save
      flash[:success] = "New API key created."
      redirect_to user_api_key_url(current_user, @key)
    else
      render 'new'
    end
  end


  def edit
    # TODO
  end


  def update
    # TODO
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


  private


    # Rails strong parameters
    def api_key_params
      params.require(:api_key).permit(:description)
    end

    def correct_user
      redirect_to root_url if params[:user_id] != current_user.id.to_s
    end

    def generate_api_key
      loop do
        token = SecureRandom.hex(12)
        break token unless ApiKey.exists?(token: token)
      end
    end

end
