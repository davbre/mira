require 'csv'
require 'tempfile'
require 'load_dynamic_AR_class_with_scopes'

class LoadTable

  include ApplicationHelper

  attr_reader :table_name, :column_list, :column_type_hash


  def initialize(datasource, datapackage_resource, upload_method)

    @ds = datasource
    @datapackage_resources = DatapackageResource.where(datapackage_id: @ds.datapackage_id)
    @table_metadata = datapackage_resource
    load_logger.info("Initialising load of #{@table_metadata.table_ref}")
    @column_metadata = DatapackageResourceField.where(datapackage_resource_id: @table_metadata.id)
    @csv_file = File.open(@ds.datafile.path)
    @upload_method = upload_method

    upload_to_db_table

  end


  private

  def load_logger
    log_dir = Project.find(@ds.project_id).job_log_path
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @load_logger ||= Logger.new("#{log_dir}/#{@ds.datafile_file_name}.log")
  end


  def new_col_name(name)
    name.parameterize.underscore
  end


  def upload_to_db_table
    if @upload_method == "quick"
      quick_upload_to_db_table
    else
      slow_upload_to_db_table
    end
  end


  def slow_upload_to_db_table
    ar_table_klass = get_mira_ar_table(@table_metadata.db_table_name)
    CSV.foreach(@csv_file, headers: true) do |row|
      ar_table_klass.create! row.to_hash
    end
  end


  def quick_upload_to_db_table
    # columns in correct order
    column_names = @column_metadata.sort{ |a,b| a.order <=> b.order }.map{ |c| new_col_name(c.name) }
    column_string = "\"#{column_names.join('","')}\""
    csv_options = "DELIMITER '#{@table_metadata.delimiter}' CSV"
    skip_header_line = @csv_file.gets
    # https://github.com/theSteveMitchell/postgres_upsert
    ActiveRecord::Base.connection.raw_connection.copy_data "COPY #{@table_metadata.db_table_name} (#{column_string}) FROM STDIN #{csv_options} QUOTE '#{@table_metadata.quote_character}'" do
      while line = @csv_file.gets do
        next if line.strip.size == 0
        ActiveRecord::Base.connection.raw_connection.put_copy_data line
      end
    end
  end


end
