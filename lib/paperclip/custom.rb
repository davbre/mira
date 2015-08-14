require 'csv'
module Paperclip

  # https://github.com/thoughtbot/paperclip#post-processing
  # http://www.rubydoc.info/gems/paperclip/Paperclip/Processor
  class Custom < Processor

    def initialize(file, options = {}, attachment = nil)
      super
      # @file, @options and @attachment are available from super
      # Rails.logger.info("In Custom processor!!")
      @basename = File.basename(file.path)
      @column_list = get_columns
      # TODO: currently mapping all columns to string. Need to update.
      @column_type_hash = Hash[@column_list.map {|c| [c,"string"]}]
    end

    def make
      create_db_table
      upload_to_db_table
      @file # we don't actually do anything with file but "make" must return a file
    end


    private

    def get_columns
#      binding.pry
      line = File.open(@file.path).gets.gsub(/\\"/,'""')
      # column_list = CSV.parse(line.strip.split(@options[:delimiter]))
      column_list = CSV.parse(line, { :col_sep => @options[:delimiter]}).first # returns an array of arrays. We only read one line so want first element of array
      return column_list.map!(&:downcase)
    end

    def create_db_table
      ActiveRecord::Base.connection.create_table @table_name.to_sym do |t|
        @column_type_hash.each do |new_colname,new_coltype|
          # The following mimics what is seen in migrations, e.g.:
          #   t.string :name
          #   t.text   :description
          t.send new_coltype.to_s, new_colname
        end
      end
    end

    def upload_to_db_table
      column_string = "\"#{@column_list.join('","')}\""
      csv_options = "DELIMITER '#{@options[:delimiter]}' CSV"
      ActiveRecord::Base.connection.raw_connection.copy_data "COPY #{@table_name} (#{column_string}) FROM STDIN #{csv_options}" do
        while line = @file.gets do
          next if line.strip.size == 0
          ActiveRecord::Base.connection.raw_connection.put_copy_data line
        end    
      end
    end

  end

end