require 'csv'
require 'tempfile'
require 'load_dynamic_AR_class_with_scopes'

# Bits and pieces from https://github.com/theSteveMitchell/postgres_upsert
class LoadTable

  attr_reader :table_name, :column_list, :column_type_hash

  # Mapping from JSON schema table types to Active Record types:
  @@type_map = {
      "boolean" => "boolean",
      "integer" => "integer",
      "number" => "float",
      "float" => "float",
      "geopoint" => "float",     # seen in airport-codes dataset although have not found any documentation for it!
      "datetime" => "datetime",
      "date" => "date",
      "time" => "time",
      "string" => "text",
      "null" => "text"
    }

  def initialize(datasource, datapackage)

    @ds = datasource

    load_logger.info("Initialising load of #{@ds.table_ref}")

    # @options = { :delimiter => "," }

    @load_errors = []

    # @tmpfile = Tempfile.new('mira-load-table')

    # s3 = Aws::S3::Client.new(:region => ENV['S3_REGION'])
    # File.open(@tmpfile, 'wb') do |file|
    #   reap = s3.get_object({ bucket: ENV['S3_BUCKET'], key: datasource.datafile.s3_object.key }, target: file)
    # end
    @tmpfile = File.open(@ds.datafile.path)

    @datapackage_data = datapackage["resources"].select { |res| res["path"].split("/").last == datasource.datafile_file_name }[0]

    load_logger.info("====>   Fetching column information from datapackage   <====")
    @column_info = get_column_info

    load_logger.info("====>   Creating database table " + @ds.db_table_name + "   <====")
    create_db_table

    load_logger.info("====>   Uploading " + @ds.datafile_file_name + " to " + @ds.db_table_name + "   <====")
    upload_to_db_table

    # It is not really necessary to store the public url or the region in the
    # database but it may be useful later on.
    # The same information (more or less) could be obtained as follows:
    #   Datasource.find(:id).datafile.url
    #   Datasource.find(:id).s3_object.config.s3_region
    #datasource.public_url = datasource.datafile.s3_object.public_url.to_s
    #datasource.s3_region = datasource.datafile.s3_object.config.s3_region
    #datasource.save
  end

  private

  def load_logger
    log_dir = Rails.configuration.x.job_log_path + "/project_#{@ds.project_id}"
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @load_logger ||= Logger.new("#{log_dir}/#{@ds.datafile_file_name}.log")
  end


  def get_column_info
    column_info = {}

    # get json table schema from datapackage data (http://dataprotocols.org/json-table-schema/)
    jts_columns = @datapackage_data["schema"]["fields"]

    jts_columns.each_with_index do |col,i|

      begin
        ar_type = @@type_map[col["type"]]
        if ar_type.nil?
          raise "Failed to map datapackage json column type --> " + col["type"] + " <-- to Active Record type!"
        end
      rescue StandardError => e
        @load_logger.error(e)
      end

      column_info[i+1] = {
        :name => col["name"].parameterize.underscore,
        :jason_schema_table_type => col["type"],
        :active_record_type => ar_type
      }

      column_info[i+1][:min] = col["constraints"]["minimum"] if col["constraints"] && col["constraints"]["minimum"]
      column_info[i+1][:max] = col["constraints"]["maximum"] if col["constraints"] && col["constraints"]["maximum"]

    end
    column_info
  end


  def create_db_table
    # Create table with columns
    begin
      ActiveRecord::Base.connection.create_table @ds.db_table_name.to_sym do |t|
        @column_info.each do |colindex,colhash|
          # The following mimics what is seen in migrations, e.g.:
          #   t.string :name
          #   t.text   :description
          # Cater for big integers
          if colhash[:active_record_type] == "integer" && [colhash[:min].to_i.abs,colhash[:max].to_i.abs].max > 2147483647
            t.send colhash[:active_record_type], colhash[:name], :limit => 8
          else
            t.send colhash[:active_record_type], colhash[:name]
          end
        end
      end

      # Add an index for each column
      @column_info.each do |colindex,colhash|
        ActiveRecord::Base.connection.add_index @ds.db_table_name.to_sym, colhash[:name]
      end    
    rescue StandardError => e
      load_logger.error(e)
    end

  end

  def upload_to_db_table

    begin
      delimiter = get_delimiter(@datapackage_data)
      quote_char = get_quote_char(@datapackage_data)
      column_names = @column_info.map { |k,v| v[:name] }
      column_string = "\"#{column_names.join('","')}\""
      csv_options = "DELIMITER '#{delimiter}' CSV"
      skip_header_line = @tmpfile.gets
      # https://github.com/theSteveMitchell/postgres_upsert
      ActiveRecord::Base.connection.raw_connection.copy_data "COPY #{@ds.db_table_name} (#{column_string}) FROM STDIN #{csv_options} QUOTE '#{quote_char}'" do
        while line = @tmpfile.gets do
          next if line.strip.size == 0
          ActiveRecord::Base.connection.raw_connection.put_copy_data line
        end    
      end
    rescue StandardError => e
      load_logger.error(e)
      raise e
    end

  end


  def get_delimiter(dp_metadata)

    if dp_metadata.has_key?("dialect") && (dp_metadata["dialect"].has_key? "delimiter") then
      delimiter = dp_metadata["dialect"]["delimiter"]
    else
      load_logger.info("datapackage.json does not specify the delimiter (via 'dialect': { 'delimiter': '?'}). Defaulting to a comma.")
      delimiter = ','
    end
    delimiter

  end


  def get_quote_char(dp_metadata)
    if dp_metadata.has_key?("dialect") && (dp_metadata["dialect"].has_key? "quote") then
      quote_char = dp_metadata["dialect"]["quote"]
      quote_char = "''" if quote_char == "'" # http://stackoverflow.com/a/12857090/1002140
    else
      load_logger.info("datapackage.json does not specify a quote characher (via ['dialect']['quote']). Defaulting to a double quote.")
      quote_char = '"'
    end
    quote_char
  end

end
  