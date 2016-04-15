class ApiKeysController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper
  include ProjectHelper

  before_action :authenticate_user!, except: [ :index, :show, :api_detail ]
  before_action :correct_user, only: [ :destroy, :edit, :update ]


  def index
    @keys = ApiKey.order(id: :desc).page params[:page] # kaminari
  end


  def show
    @key = ApiKey.find(params[:id])
  end


  def new
    @key = ApiKey.new
    @user = current_user
  end


  def create
    binding.pry
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
    @key = ApiKey.find(params[:id])
  end


  def update
  end


  def destroy
  end


  private


    # Rails strong parameters
    def api_key_params
      binding.pry
      params.permit(:description)
    end

    def correct_user
      @key = current_user.api_keys.find_by(id: params[:id])
      redirect_to root_url if @key.nil?
    end

    def generate_api_key
      loop do
        token = SecureRandom.hex(12)
        break token unless ApiKey.exists?(token: token)
      end
    end

end
