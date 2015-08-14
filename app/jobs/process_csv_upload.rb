require 'load_table'
require 'net/http'


# https://github.com/collectiveidea/delayed_job#custom-jobs
class ProcessCsvUpload

  include Rails.application.routes.url_helpers 

  def initialize(datasource_id, datapackage)
    @ds = Datasource.find(datasource_id)
    @datapackage = datapackage
  end

  def job_logger
    log_dir = Rails.configuration.x.job_log_path + "/project_#{@ds.project.id}"
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @job_logger ||= Logger.new("#{log_dir}/#{@ds.datafile_file_name}.log")
  end

  def max_attempts
    1
  end

  def perform
    job_logger.info("About to process " + @ds.datafile_file_name)
    new_upload_table = LoadTable.new(@ds,@datapackage)
  end

  def success
    job_logger.info("Finished uploading " + @ds.datafile_file_name + " to the database")
    # TODO log some upload info, number or rows, column names.    
  end

  def error
    job_logger.error("Something went wrong while loading " + @ds.datafile_file_name + " into the database...")
    job_logger.error(exception)
  end
end