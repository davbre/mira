require 'csv'
require 'tempfile'
require 'load_dynamic_AR_class_with_scopes'

class LoadTable

  attr_reader :table_name, :column_list, :column_type_hash

  def initialize(datasource)

    @ds = datasource
    load_logger.info("Initialising load of #{@ds.table_ref}")
    @datapackage_resources = DatapackageResource.where(datapackage_id: @ds.datapackage_id)
    @table_metadata = @datapackage_resources.where(path: @ds.datafile_file_name).first
    @column_metadata = DatapackageResourceField.where(datapackage_resource_id: @table_metadata.id)
    @csv_file = File.open(@ds.datafile.path)

    load_logger.info("====>   Creating database table " + @ds.db_table_name + "   <====")
    create_db_table

    load_logger.info("====>   Uploading " + @ds.datafile_file_name + " to " + @ds.db_table_name + "   <====")
    upload_to_db_table

  end

  private

  def load_logger
    log_dir = Project.find(@ds.project_id).job_log_path
    Dir.mkdir(log_dir) unless File.directory?(log_dir)
    @load_logger ||= Logger.new("#{log_dir}/#{@ds.datafile_file_name}.log")
  end


  def create_db_table
    # Create table with columns
    # If "id" already exists in the csv file, then we don't want ActiveRecord to create this variable
    # (which it does by default)
    create_table_options = @column_metadata.map { |a| a.name }.exclude?("id") ? {} : {id: false}
    load_logger.info("'id' column already exists so ActiveRecord's default 'id' column will not be added to the table") unless create_table_options == { id: false }

    ActiveRecord::Base.connection.create_table(@ds.db_table_name.to_sym, create_table_options) do |t|
      @column_metadata.each do |col|
        # The following mimics what is seen in migrations, e.g.:
        #   t.string :name
        #   t.text   :description
        # Cater for big integers
        if DATAPACKAGE_TYPE_MAP[col.ftype] == "integer" && col.big_integer == true
          t.send DATAPACKAGE_TYPE_MAP[col.ftype], col.name, :limit => 8
        else
          t.send DATAPACKAGE_TYPE_MAP[col.ftype], col.name
        end
      end
    end

    # Add an index for each column
    @column_metadata.each do |col|
      ActiveRecord::Base.connection.add_index @ds.db_table_name.to_sym, col.name
    end
  end

  def upload_to_db_table

    # columns in correct order
    column_names = @column_metadata.sort{ |a,b| a.order <=> b.order }.map{ |c| c.name }
    column_string = "\"#{column_names.join('","')}\""
    csv_options = "DELIMITER '#{@table_metadata.delimiter}' CSV"
    skip_header_line = @csv_file.gets
    # https://github.com/theSteveMitchell/postgres_upsert
    ActiveRecord::Base.connection.raw_connection.copy_data "COPY #{@ds.db_table_name} (#{column_string}) FROM STDIN #{csv_options} QUOTE '#{@table_metadata.quote_character}'" do
      while line = @csv_file.gets do
        next if line.strip.size == 0
        ActiveRecord::Base.connection.raw_connection.put_copy_data line
      end
    end

  end

end
