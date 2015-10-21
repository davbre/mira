require 'net/http'
require 'json'
require 'fileutils'

class ProjectsController < ApplicationController

  include ApplicationHelper
  include DatapackageHelper

  before_action :authenticate_user!, except: [ :index, :show, :api_detail ]
  before_action :correct_user, only: [ :destroy, :edit, :update ]


  def index
    @projects = Project.order(id: :desc).page params[:page] # kaminari
  end

  def show
  	@project = Project.find(params[:id])
    @datasources = @project.datasources.where.not(datapackage_id: nil).order(:table_ref,:archived)
    @datapackage = @project.datapackage
    log_files = Dir.glob(Rails.configuration.x.job_log_path + "/project_" + @project.id.to_s + '/*.log')
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


  def upload_datapackage

    @project = Project.find(params[:id])
    @feedback = { errors: [], warnings: [], notes: [] }
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

    if @feedback[:errors].any?
      @project.errors.add(:datapackage, @feedback[:errors])
      render 'edit'
    else
      flash[:success] = "datapackage.json uploaded"
      extract_and_save_datapackage_resources(@datapackage,json_dp)
      # json_dp["resources"].each do |res|
      #   if extract_and_save_datapackage_resource(@datapackage,res) == false
      #     @project.errors.add(:datapackage_resource, "Failed to extract metadata for " + res["path"] + from + " datapackage.json")
      #   end
      # end
      redirect_to @project
    end

  end


  def check_and_clean_datapackage(dp)
    feedback = { errors: [], warnings: [], notes: []}
    if dp.nil?
      @feedback[:errors] << "You must upload a datapackage.json file."
    else
      dp_path = dp.tempfile.path
      dp_file = File.read(dp_path)

      json_dp = {}
      begin
        json_dp = JSON.parse(dp_file)
        @feedback[:errors] << "datapackage.json must contain 'resources'." if !json_dp.has_key? "resources"
        @feedback[:errors] << "datapackage.json must contain a 'resources' array." if json_dp.has_key? "resources" && json_dp["resources"].class != Array
        @feedback[:errors] << "datapackage.json must contain a non-empty 'resources' array." if json_dp.has_key? "resources" && !json_dp["resources"].empty?
      rescue => e
        @feedback[:errors] << e
      end

      json_dp, trim_feedback = trim_datapackage(json_dp)
      feedback.merge!(trim_feedback) {|key, oldval, newval| oldval + newval }

      if @feedback[:errors].empty?
        json_dp["resources"].each do |resource|
          @feedback[:errors] << "Each resource must have a path." if !resource.has_key? "path"
          @feedback[:errors] << "Each resource must have a schema." if !resource.has_key? "schema"

          if resource.has_key? "path"
            if resource["path"].class != String
              @feedback[:errors] << "Resource path must be a String, e.g. 'path/to/mydata.csv' (" + resource["path"].to_s + ")."
            elsif [nil, ""].include? resource["path"]
              @feedback[:errors] << "Resource 'path' is empty."
            elsif resource["path"].split("/").last.downcase == "csv"
              @feedback[:errors] << "Resource 'path' should refer to a csv file (" + resource["path"].to_s + ")."
            end
          end

          if resource.has_key? "path" and resource.has_key? "schema"
            if resource["schema"].class != Hash
              @feedback[:errors] << "Resource 'schema' must be a Hash (path: " + resource["path"].to_s + ")."
            elsif !resource["schema"].has_key? "fields"
              @feedback[:errors] << "Resource 'schema' must contain 'fields' (path: " + resource["path"].to_s + ")."
            elsif resource["schema"]["fields"].class != Array
              @feedback[:errors] << "Resource schema 'fields' must be an Array (" + resource["path"].to_s + ")."
            else
              resource["schema"]["fields"].each do |field|
                if not (field.has_key? "name" and field.has_key? "type")
                  @feedback[:errors] << "Each resource schema field must contain 'name' and 'type' keys (path: " + resource["path"].to_s + ")."
                else
                  if (field["name"] =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) == nil
                    @feedback[:errors] << "Field name is not valid: " + field["name"] + "."
                  end
                  unless DATAPACKAGE_TYPE_MAP.keys.include? field["type"].downcase
                    @feedback[:errors] << "Field type is not valid. Field: " + field["name"] + ", type: " + field["type"] + ". " +
                                         "Valid types are " + DATAPACKAGE_TYPE_MAP.keys.join(", ") + "."
                  end
                end
              end
            end
          end
        end
      end
      json_dp
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
      ds.delete_associated_artefacts
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

    def check_datapackage_old(datapackage)
      check_results = { errors: []}

      # datapackage["resources"].each do |res|
      #   check_results[:errors] << "Each resource must have a 'path' giving the csv file name" unless res.has_key? "path"
      # end
      dp_file_names = datapackage["resources"].map { |r| r["path"].split("/").last }
      dp_file_formats = datapackage["resources"].map { |r| r["format"] }
      dp_schemas = datapackage["resources"].map{ |r| r["schema"] }

      if dp_file_names.empty?
        check_results[:errors] << "No csv files found in datapackage (the path property specifies the csv file name)."
      end
      if dp_file_formats != [nil] && dp_file_formats.map(&:downcase).uniq != "csv"
        check_results[:errors] << 'The datapackage "path" property should reference csv files only!'
      end
      if [dp_file_names.length, dp_file_formats.length, dp_schemas.length].uniq.length > 1
        check_results[:errors] << 'Every csv file must have a "format" property ("csv"), a "path" (file name with ".csv") and a schema'
      end
      # TODO check for delimiter (maybe warning array)
      # TODO check ??
      check_results
    end

    def save_datapackage(dp)
      dp.save # save first...then can get public url
      dp.public_url = dp.datapackage.url.partition("?").first
      dp.save
    end

    # def save_trimmed_datapackage_file(original_dp,json_dp)
    #   feedback = { errors: [], warnings: [], notes: []}
    #
    #   File.open(original_dp.tempfile.path,"w") do |f|
    #     f.write(json_dp)
    #   end
    #   new_dp = Datapackage.new(project_id: @project.id,
    #                            datapackage: File.open(original_dp.tempfile.path),
    #                            datapackage_file_name: "datapackage.json")
    #   if new_dp.valid?
    #     save_datapackage(new_dp)
    #     @feedback[:notes] << "Saving trimmed datapackage.json"
    #   else
    #     @feedback[:errors] << "Failed to save datapackage.json:"
    #     new_dp.errors.to_a.each do |e|
    #       @feedback[:errors] << "  --validation error: " + e
    #     end
    #   end
    #   [new_dp, feedback]
    # end


    def trim_datapackage(json_dp)
      # remove all datapackage.json keys which are not needed (e.g. README). Doing this here
      # because embedded html spooks the server. It detects content-spoofing and getting the
      # error "Datapackage has contents that are not what they are reported to be"
      json_dp.each do |k,v|
        if !["name","title","description","resources"].include? k
          @feedback[:notes] << "Trimming '" + k + "' attribute from datapackage.json"
          json_dp.delete(k)
        end
      end
      [json_dp, feedback]
    end

    # def extract_and_save_datapackage_resource(dp, res)
    #   # if here we should already be sure that the path and schema are present
    #   dp_res = DatapackageResource.new(datapackage_id: dp.id, path: res["path"], schema: res["schema"])
    #   dp_res.format = res["format"] if res.has_key? "format"
    #   dp_res.delimiter = res["dialect"]["delimiter"] if res.has_key? "dialect" and res["dialect"].has_key? "delimiter"
    #   dp_res.mediatype = res["mediatype"] if res.has_key? "mediatype"
    #   dp_res.save
    # end

    def extract_and_save_datapackage_resources(dp_object,json_dp)
      json_dp["resources"].each do |res|
        dp_res = DatapackageResource.new(datapackage_id: dp_object.id, path: res["path"], schema: res["schema"].to_json)
        dp_res.format = res["format"] if res.has_key? "format"
        dp_res.delimiter = res["dialect"]["delimiter"] if res.has_key? "dialect" and res["dialect"].has_key? "delimiter"
        dp_res.mediatype = res["mediatype"] if res.has_key? "mediatype"
        if dp_res.valid?
          dp_res.save
          extract_and_save_resource_fields(dp_res)
        else
          @feedback[:errors] << "Could not save datapackage resource " + res["path"] + ". ERRORS: " + dp_res.to_a.join(", ") + "."
        end
      end
    end


    def extract_and_save_resource_fields(resource)
      feedback = { errors: [], warnings: [], notes: []}
      resource_schema = JSON.parse(resource.schema)
      resource_schema["fields"].each_with_index do |field,ndx|
        res_field = DatapackageResourceField.new(datapackage_resource_id: resource.id, name: field["name"], ftype: field["type"], order: ndx + 1)
        res_field.save
      end
    end
end
