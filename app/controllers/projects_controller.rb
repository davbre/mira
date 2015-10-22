require 'net/http'
require 'json'
require 'fileutils'
require 'csv'

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
    @datasources = @project.datasources
    @datapackage = @project.datapackage
    @datapackage_resources = @datapackage.present? ?  @datapackage.datapackage_resources : nil
    # if there exists a datasource with the same name as a datapackage_resource then it was uploaded
    # @datapackage_resources.each do |dr|
    #   @datasources.any?{ |a| a.datafile_file_name == dr.split("/").last }
    # end
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
        rescue => e
          @feedback[:errors] << "Failed to parse datapackage.json"
        else
          @feedback[:errors] << "datapackage.json must contain 'resources'." if !json_dp.has_key? "resources"
          @feedback[:errors] << "datapackage.json must contain a 'resources' array." if json_dp.has_key? "resources" && json_dp["resources"].class != Array
          @feedback[:errors] << "datapackage.json must contain a non-empty 'resources' array." if json_dp.has_key? "resources" && json_dp["resources"].present?
        end

        json_dp = trim_datapackage(json_dp)

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


    def save_datapackage(dp)
      dp.save # save first...then can get public url
      dp.public_url = dp.datapackage.url.partition("?").first
      dp.save
    end


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
      json_dp
    end


    def extract_and_save_datapackage_resources(dp_object,json_dp)
      json_dp["resources"].each do |res|
        dp_res = DatapackageResource.new(datapackage_id: dp_object.id, path: res["path"], schema: res["schema"].to_json)
        dp_res.format = res["format"] if res.has_key? "format"
        dp_res.mediatype = res["mediatype"] if res.has_key? "mediatype"
        dp_res.delimiter = res["dialect"]["delimiter"] if res.has_key? "dialect" and res["dialect"].has_key? "delimiter"
        qchar = '"'
        if res.has_key? "dialect" and res["dialect"].has_key? "quote"
          qchar_len = res["dialect"]["quote"].length
          if qchar_len > 1
            @feedback[:errors] << "Quote character must be a single character."
          elsif qchar_len != 0
            qchar = res["dialect"]["quote"]
          end
        else
          @feedback[:notes] << "datapackage.json does not specify a quote character so it defaults to a double quote."
        end
        dp_res.quote_character = qchar

        if dp_res.valid? && @feedback[:errors].empty?
          dp_res.save
          extract_and_save_resource_fields(dp_res)
        else
          @feedback[:errors] << "Datapackage resource not saved for " + res["path"] + ". ERRORS: " + dp_res.to_a.join(", ") + "."
        end
      end
    end


    def extract_and_save_resource_fields(resource)
      feedback = { errors: [], warnings: [], notes: []}
      resource_schema = JSON.parse(resource.schema)
      resource_schema["fields"].each_with_index do |field,ndx|
        res_field = DatapackageResourceField.new(datapackage_resource_id: resource.id, name: field["name"], ftype: field["type"], order: ndx + 1)
        if field["constraints"].present?
          field_min = custom_is_string_int?(field["constraints"]["minimum"]) ? field["constraints"]["minimum"].to_i : 0
          field_max = custom_is_string_int?(field["constraints"]["maximum"]) ? field["constraints"]["maximum"].to_i : 0
          res_field.big_integer = true if [field_min.abs, field_max.abs].max > 2147483647 # 2^31-1
        end
        res_field.save
      end
    end

    def custom_is_string_int?(str) # http://stackoverflow.com/a/1235990/1002140
       /\A[-+]?\d+\z/ === str
    end


    def save_datasource(csv)
      csv_file = File.open(csv.tempfile.path)
      ds = @project.datasources.create(datafile: csv_file, datafile_file_name: csv.original_filename, datapackage_id: @datapackage.id) # ds = datasource
      if ds.valid?
        set_datasource_table_name(ds)
        ds.public_url = ds.datafile.url.partition("?").first
      else
        @feedback[:errors] << "Failed to create datasource. Errors: " + ds.errors.to_a.join(", ")
      end
      retval = ds.save ? ds : nil
      retval
    end


    def set_datasource_table_name(ds)
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
    end


    def check_datasources
      if @datapackage.nil?
        @feedback[:errors] << "This project has no associated datapackage."
      elsif @csv_uploads.nil? || @csv_uploads.empty?
        @feedback[:errors] << "You must upload one or more csv files."
      elsif @datapackage.datapackage_resources.nil?
        @feedback[:errors] << "This project's datapackage has no resource metadata."
      else
        datasource_filenames = @csv_uploads.map { |u| u.original_filename }
        datapackage_filenames = @datapackage.datapackage_resources.map { |ds| ds.path }
        @csv_uploads.each do |csv|
          if csv.original_filename !~ /\.csv/i
            @feedback[:errors] << "Only csv files should be uploaded. You uploaded " + csv.original_filename + "."
          elsif datapackage_filenames.exclude? csv.original_filename
            @feedback[:errors] << "This project's datapackage has no metadata for " + csv.original_filename + "."
          else
            dp_res = @datapackage.datapackage_resources.where(path: csv.original_filename).first
            dp_res_fields = dp_res.datapackage_resource_fields
            if dp_res_fields.empty?
              @feedback[:errors] << "This project's datapackage has metadata for " + csv.original_filename + " but not for its fields!" # shouldn't reach here (bug otherwise)
            else
              # At this point we know we have metadata for all uploaded files (via
              # the processing of the uploaded datapackage.json file).
              # Do a quick check of each csv file.
              dp_res_fields = dp_res.datapackage_resource_fields
              csv_actual_fields = CSV.open(csv.tempfile, 'r') { |csvfile| csvfile.first }.sort
              csv_metadata_fields = dp_res_fields.map { |f| f.name }.sort
              if csv_actual_fields != csv_metadata_fields
                @feedback[:errors] << "The datapackage.json field names for " + csv.original_filename +
                                      " do not match the fields in the csv file. Expected: [" +
                                      csv_metadata_fields.join(", ") + "]. Actual: [" + csv_actual_fields.join(", ") + "]."
              end
            end
          end
        end
      end
    end
end
