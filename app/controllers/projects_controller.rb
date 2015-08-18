require 'net/http'
require 'json'
require 'fileutils'

class ProjectsController < ApplicationController

  include ApplicationHelper

  before_action :authenticate_user!, except: [ :index, :show, :api_detail ]
  before_action :correct_user, only: [ :destroy, :edit, :update ]


  def index
    @projects = Project.order(id: :desc).page params[:page] # kaminari
  end

  def show
  	@project = Project.find(params[:id])
    @datasources = @project.datasources.where.not(datapackage_id: nil).order(:table_ref,:archived)    
    @datapackages = @project.datasources.where(datapackage_id: nil).order(:archived,:datafile_file_name)
    log_files = Dir.glob(Rails.configuration.x.job_log_path + "/project_" + @project.id.to_s + '/*.log')
    @log_file_names = log_files.map { |l| l.split("/").last }
  end

  def new
  	@project = Project.new
  end

  def create
  	@project = current_user.projects.build(project_params)
  	if @project.save
      flash[:success] = "New project created. Upload some files!"
      # same as: redirect_to project_url(@project)
      redirect_to @project
  	else
  	  render 'new'
  	end
  end


  def upload_ds
    @project = Project.find(params[:id])

    datasources_errors = []

    if params[:datafiles].nil? || params[:datafiles].empty?
      @project.errors.add(:uploads, "you must upload one or more csv files along with their datapackage.json file")
    else
      dp_index = params[:datafiles].find_index{ |a| a.original_filename == "datapackage.json" }
      csv_files = params[:datafiles].select { |df| df.content_type == "text/csv" }
      non_csv_files = params[:datafiles].select { |df| df.content_type != "text/csv" && df.original_filename != "datapackage.json"}

      if dp_index.nil?
        @project.errors.add(:uploads, "no datapackage.json was uploaded")
      elsif csv_files.empty?
        @project.errors.add(:uploads, "no csv files were uploaded")
      elsif non_csv_files.any?
        @project.errors.add(:uploads, "only csv files can be uploaded along with their datapackage.json file")
      else

        # hash mapping original filename to its temporary location
        tempfile_location_hash = { "datapackage.json" => params[:datafiles][dp_index].tempfile.path }

        csv_files.each do |c|
          tempfile_location_hash[c.original_filename] = c.tempfile.path
        end

        Delayed::Job.enqueue CheckDatapackage.new(@project.id, tempfile_location_hash)
        flash[:success] = "Files uploading and being processed. Check the import logs."
      end
    end


    if @project.errors.any? || datasources_errors.length > 0
      datasources_errors.each { |i|
        @project.errors.add(("upload failed: ").to_sym , i)
      }
      render 'edit'
    else
      redirect_to @project
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
    @project = Project.find(params[:id])
    if @project.destroy
      # delete uploads and logs
      logs_dir = Rails.root.join("public","job_logs","project_" + params[:id].to_s)
      uploads_dir = Rails.root.join("public","uploads","project_" + params[:id].to_s)
      FileUtils.rm_rf(logs_dir) if Dir.exists? logs_dir
      FileUtils.rm_rf(uploads_dir) if Dir.exists? uploads_dir
      Dir.exists? Rails.root.join("public","job_logs","project_" + params[:id].to_s)
      flash[:success] = "Project deleted"
    else
      flash[:error] = "Failed to delete project"
    end
    redirect_to projects_url
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