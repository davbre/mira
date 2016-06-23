require 'load_table'
require 'net/http'


# https://github.com/collectiveidea/delayed_job#custom-jobs
class ProcessCsvUpload

  include Rails.application.routes.url_helpers
  include ProjectHelper

  def initialize(datasource_id,upload_method)
    @ds = Datasource.find(datasource_id)
    @dp = Datapackage.find(@ds.datapackage_id)
    mapped_csv_name = map_csv_basename(@dp, basename(@ds.datafile_file_name))
    @datapackage_resource = DatapackageResource.where(datapackage_id: @dp.id, table_ref: mapped_csv_name).first
    @upload_method = upload_method
  end

  def job_logger
    log_dir = Project.find(@ds.project_id).job_log_path
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @job_logger ||= Logger.new("#{log_dir}/#{@ds.datafile_file_name}.log")
  end

  def max_attempts
    1
  end

  def perform
    # puts "About to process: " + @ds.datafile_file_name
    job_logger.info("About to process " + @ds.datafile_file_name + " using '" + @upload_method + "' upload method")
    LoadTable.new(@ds, @datapackage_resource, @upload_method)
  end

  def success
    job_logger.info("Finished uploading " + @ds.datafile_file_name + " to the database")
    # we can now set the datasource_id in the datapackage_resource table as we
    # know it has been uploaded
    # @datapackage_resource.datasource_id = @ds.id
    if @datapackage_resource.save
      job_logger.info("Saved the datasource_id to the datapackage_resource table")
      @ds.ok!
    else
      job_logger.error("Unexpected - failed to save datasource ID to datapackage_resource table!")
      @ds.error!
    end
    # TODO log some upload info, number or rows, column names.
  end

  def error(job,exception)
    # if @datapackage_resource.save
    #   job_logger.info("Saved the datasource_id to the datapackage_resource table")
    # end
    job_logger.error("Something went wrong while loading " + @ds.datafile_file_name + " into the database...")
    job_logger.error(exception)
    @ds.error!
  end

end
