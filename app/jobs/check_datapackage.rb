
class CheckDatapackage


   def initialize(project_id, tempfile_locations)
     @project = Project.find(project_id)
     @tempfile_locations = tempfile_locations
     @now_timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
   end

   # separate log for each job
   # http://stackoverflow.com/questions/337739/how-to-log-something-in-rails-in-an-independent-log-file
  def job_logger
    log_dir = Rails.configuration.x.job_log_path + "/project_#{@project.id}"
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @@job_logger ||= Logger.new("#{log_dir}/datapackage.json.log")
  end

  def max_attempts
    1
  end

  def perform
    extant_dp_file = @project.datasources.where(:datafile_file_name => "datapackage.json").first
    ds_archive("datapackage.json") unless extant_dp_file.nil?

    datapackage_tempfile_path = @tempfile_locations.delete("datapackage.json")
    datapackage_file = File.read(datapackage_tempfile_path)
    datapackage = JSON.parse(datapackage_file)

    dp_file_names = datapackage["resources"].map { |r| r["path"].split("/").last }
    dp_file_formats = datapackage["resources"].map { |r| r["format"] }
    job_logger.info("datapackage.json resources: " + dp_file_names.sort.to_s)
    job_logger.info("uploaded csv files:         " + @tempfile_locations.keys.sort.to_s)


    # make sure details of all csv files are in the datapackage
    missing_metadata = (@tempfile_locations.keys - dp_file_names)
    if missing_metadata.any?
      raise "datapackage.json has not metadata for csv files: " + missing_metadata.to_s
    else

      extant_csv_files = @project.datasources.map { |d| d.datafile_file_name if d.datafile_file_name.include? "csv" } - [nil]

      dp = @project.datasources.create(datafile: File.open(datapackage_tempfile_path), datafile_file_name: "datapackage.json")

      if dp.valid?
        save_dp(dp)
      else
        # If can't save datapackage, then we trim some attributes and try again
        job_logger.warn("Content-type should be application/json. The server determines the file to be of content-type: " + dp.datafile_content_type + ".")
        job_logger.warn("An attempt will be made to remove some attributes (e.g. readme) from datapackage.json")
        trimmed_dp = trim_datapackage(datapackage)
        File.open(datapackage_tempfile_path,"w") do |f|
          f.write(trimmed_dp.to_json)
        end
        dp2 = @project.datasources.create(datafile: File.open(datapackage_tempfile_path), datafile_file_name: "datapackage.json")
        if dp2.valid?
          job_logger.info("Saving trimmed datapackage.json")
          save_dp(dp2)
        else
          raise "Failed to save datapackage.json. Errors: " + dp2.errors.to_a.to_s
        end
      end

      # save and process csv files
      @tempfile_locations.sort.each do |csv,path|

        ds_archive(csv) if extant_csv_files.include? csv        

        cfile = File.open(path)
        job_logger.info("Queuing job to process " + csv)
        ds = @project.datasources.create(datafile: cfile, datafile_file_name: csv, datapackage_id: dp.id) # ds = datasource
        if ds.valid?
          set_table_name(ds)
          ds.public_url = ds.datafile.url.partition("?").first
          ds.save
          Delayed::Job.enqueue ProcessCsvUpload.new(ds.id,datapackage)
        else
          job_logger.error("validation failed for file: " + ds.datafile_file_name)
          job_logger.error("---> " + ds.errors)
        end
      end

    end
  end



  def success
    job_logger.info("Finished queuing csv files for processing")
  end

  def error(job, exception)
    job_logger.error("Something went wrong while checking the datapackage.json file...")
    job_logger.error(exception)
  end


  private

    def set_table_name(ds)
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
    end

    def ds_archive(datasource)

      job_logger.info("About to archive existing file " + datasource)
      extant_ds = @project.datasources.where(datafile_file_name: datasource).first
      timestamp = extant_ds.created_at.strftime("%Y%m%d-%H%M%S")
      orig_ds_filename = extant_ds.datafile_file_name
      new_fn_arr = orig_ds_filename.split(".")
      new_ds_filename = new_fn_arr[0].to_s + "-" + timestamp + "." + new_fn_arr[1..-1].join

      # Change datasources database table (this doesn't actually change the file's name)
      extant_ds.datafile_file_name = new_ds_filename
      extant_ds.table_ref = extant_ds.table_ref + "-" + timestamp
      extant_ds.public_url = Pathname(extant_ds.public_url).dirname.to_s + "/" + extant_ds.datafile_file_name
      extant_ds.archived = true
      extant_ds.save

      # Change actual filename, and its log filename
      begin
        project_upload_path = Rails.public_path.to_s + Pathname(extant_ds.public_url).dirname.to_s + "/"
        project_job_log_path = Rails.configuration.x.job_log_path + "/project_" +  extant_ds.project_id.to_s + "/"
        File.rename project_upload_path + orig_ds_filename, project_upload_path + new_ds_filename
        File.rename project_job_log_path + orig_ds_filename + ".log", project_job_log_path + new_ds_filename + ".log"
      rescue StandardError => e
        job_logger.error("Failed to rename archived files:")
        job_logger.error(e)
      end
    end


    def save_dp(dp)
      job_logger.info("Saving datapackage.json and creating publicly accessible url")
      dp.public_url = dp.datafile.url.partition("?").first
      dp.save
    end

    def trim_datapackage(dp)
      check = ["readme", "readmeHtml", "readme_html", "README", "READMEHTML", "README_HTML"]
      check.each do |chk|
        del = dp.delete(chk)
        if not del.nil?
          job_logger.info("Trimming '" + chk + "' attribute from datapackage.json")
        end
      end
      dp
    end
end
