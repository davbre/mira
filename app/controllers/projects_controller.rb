require 'net/http'
require 'json'
require 'fileutils'
require 'csv'

class ProjectsController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper
  include ProjectHelper

  before_action :authenticate_user!, except: [ :index, :show, :api_detail ]
  before_action :correct_user, only: [ :destroy, :edit, :update ]


  def index
    @projects = Project.order(id: :desc).page params[:page] # kaminari
  end

  def show
  	@project = Project.find(params[:id])
    @datasources = @project.datasources
    @datapackage = @project.datapackage
    @datapackage_resources = @datapackage.present? ?  @datapackage.datapackage_resources : nil
    # if there exists a datasource with the same name as a datapackage_resource then it was uploaded
    # @datapackage_resources.each do |dr|
    #   @datasources.any?{ |a| a.datafile_file_name == dr.split("/").last }
    # end
    log_files = Dir.glob(@project.job_log_path + '*.log')
    @log_file_names = log_files.map { |l| l.split("/").last }
  end

  def new
  	@project = Project.new
  end

  def create
  	@project = current_user.projects.build(project_params)
  	if @project.save
      flash[:success] = "New project created. Now upload a datapackage.json file."
      Dir.mkdir(@project.job_log_path) unless File.directory?(@project.job_log_path)
      Dir.mkdir(@project.upload_path) unless File.directory?(@project.upload_path)
      # same as: redirect_to project_url(@project)
      redirect_to @project
  	else
  	  render 'new'
  	end
  end


  def edit
    @project = Project.find(params[:id])
  end


  def update
  	@project = Project.find(params[:id])
  	if @project.update_attributes(project_params)
  	  flash[:success] = "Project updated"
  	  redirect_to @project
  	else
  	  render 'edit'
  	end
  end


  def destroy
    project = Project.find(params[:id])
    project.datasources.each do |ds|
      ds.delete_associated_artifacts
    end
    FileUtils.rm_rf(project.job_log_path)
    FileUtils.rm_rf(project.upload_path)
    if project.destroy
      flash[:success] = "Project deleted"
    else
      flash[:error] = "Failed to delete project"
    end
    redirect_to projects_url
  end


  def upload_datapackage

    @project = Project.find(params[:id])
    @feedback = { errors: [], warnings: [], notes: [] }

    if @project.datapackage.present?
      @feedback[:errors] << datapackage_errors[:already_uploaded]
    elsif params[:datapackage].blank?
      @feedback[:errors] << datapackage_errors[:no_upload]
    else
      datapackage = params[:datapackage]

      json_dp = check_and_clean_datapackage(datapackage)

      # overwrite the datapackage.json temporary file with a clean/trimmed version
      File.open(datapackage.tempfile.path,"w") do |f|
        f.write(json_dp.to_json)
      end

      if json_dp.present? and @feedback[:errors].empty?
        @datapackage = Datapackage.new(project_id: @project.id,
                                       datapackage: File.open(datapackage.tempfile.path),
                                       datapackage_file_name: "datapackage.json")
        if @datapackage.valid?
          save_datapackage(@datapackage)
        else
          @feedback[:errors] += @datapackage.errors.to_a
        end
      end
    end

    if @feedback[:errors].any?
      @project.errors.add(:datapackage, @feedback[:errors])
      render 'edit'
    else
      flash[:success] = "datapackage.json uploaded"
      extract_and_save_datapackage_resources(@datapackage,json_dp)
      redirect_to @project
    end

  end


  def upload_datasources
    @project = Project.find(params[:id])
    @datapackage = @project.datapackage
    @feedback = { errors: [], warnings: [], notes: [] }
    @csv_uploads = params[:datafiles]
    @log_file_name = nil

    check_datasources

    unless @feedback[:errors].any?
      @csv_uploads.each do |csv|
        new_datasource = save_datasource(csv)
        # at this point we have saved the csv file and we know there is a
        # corresponding datapackage_resource which points to the metadata
        # required to import the csv file.
        Delayed::Job.enqueue ProcessCsvUpload.new(new_datasource.id) if new_datasource.present?
      end
    end

    if @feedback[:errors].any?
      @project.errors.add(:csv, @feedback[:errors])
      render 'show'
    else
      # flash[:success] = "datapackage.json uploaded"
      redirect_to @project
    end
  end



  def api_detail
    @project = Project.find(params[:id])
    @datasources = @project.datasources.where.not(db_table_name: nil).order(:table_ref)
  end



  private


    # Rails strong parameters
    def project_params
      params.require(:project).permit(:name, :description, datasources: [:datafile_file_name, :table_ref, :public_url])
    end

    def correct_user
      @project = current_user.projects.find_by(id: params[:id])
      redirect_to root_url if @project.nil?
    end


end
