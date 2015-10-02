require 'test_helper'

class Api::V1::DataControllerTest < ActionController::TestCase

  include Devise::TestHelpers


  setup do
    sign_in users(:one)    
    # @project = projects(:one)
    @user = users(:one)

    Delayed::Worker.delay_jobs = false # turn off queuing

    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save

    dp_file = fixture_file_upload("uploads/datapackage.json", "application/json")
    @dp = @project.datasources.create(datafile: File.open(dp_file), datafile_file_name: "datapackage.json")
    @dp.save
    @datapackage = JSON.parse(File.read(dp_file.tempfile.path))

    @uploads = ["good_upload"]

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ds = @project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @dp.id) 
      ds.save
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
      ds.save

      ProcessCsvUpload.new(ds.id,@datapackage).perform

    end
  end


  # HTTP JSON: {"id"=>1, "name"=>"John", "age"=>23, "dob"=>"2015-12-01", "score"=>12.145, "longid"=>1000000000000000000, "boolfl"=>true}
  # CSV File:  {"name"=>"John", "age"=>"23", "dob"=>"2015-12-01", "score"=>"12.145", "longid"=>"1000000000000000000", "boolfl"=>"TRUE"}
  # Type map:  {"name"=>"text", "age"=>"integer", "dob"=>"date", "score"=>"float", "longid"=>"integer", "boolfl"=>"boolean"}
  def cell_to_type(text_cell,type_map)
    # text_cell will look like ["column_name", "column_value"]
    # type_map will look like {"column_name"=>"column_type", ... }
    ret = nil
    cell_type = type_map[text_cell[0]]
    # binding.pry
    if text_cell[1].blank?
      ret = nil
    elsif ["text","date","datetime","time"].include? cell_type
      ret = text_cell[1]
    elsif cell_type == "integer"
      ret = text_cell[1].to_i
    elsif ["float","number"].include? cell_type
      ret = text_cell[1].to_f
    elsif cell_type == "boolean"
      if ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include? text_cell[1]
        ret = true
      elsif ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.include? text_cell[1]
        ret = false
      end
    end
    ret = text_cell[1] if (ret.nil? && !text_cell[1].blank?)
    ret
  end

 
  def csv_row_count(csv_file)
    row_count = File.open(csv_file,"r").readlines.size - 1
  end


  # api/projects/:id/tables/:table_ref/data
  test "API projects/:id/tables/:table_ref/data - returns JSON response with a 'data' key" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      assert json_response.key? "data"
    end
  end

  test "API projects/:id/tables/:table_ref/data - returns default number of rows" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      assert_equal [csv_row_count(csv_file),default_page_size].min, json_response["data"].length
    end
  end

  test "API projects/:id/tables/:table_ref/data - returns correct variables in every row" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_header_columns = CSV.open(csv_file, 'r') { |csv| csv.first } # http://stackoverflow.com/a/18113090/1002140
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      column_counts = {}
      json_response["data"].each do |row|
        row.each do |col,val|
          column_counts.key?(col) ? column_counts[col] += 1 : column_counts[col] = 1
        end
      end
      assert column_counts.key? "id"
      assert_equal 1, column_counts.values.uniq.length  # count the keys across "rows". At the end of count, should have same number for each column
      assert_equal default_page_size, column_counts.values.uniq.first
      assert_equal csv_header_columns, column_counts.keys - ["id"]
    end
  end


  test "API projects/:id/tables/:table_ref/data - returns correct values in every cell" do
    @uploads.each do |upl|
      mapped_col_types = map_datapackage_column_types(@datapackage, upl + ".csv")
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      # mimix the json response using csv file, then compare the two
      csv_mimic_json = { "data" => []}
      csv_table.each_with_index do |row,i|
        mimic_row = { "id" => i+1 }
        row_as_hash = row.to_hash
        row_as_hash.each do |cell|
          cell_typed = cell_to_type(cell,mapped_col_types)
          mimic_row[cell[0]] = cell_typed
        end
        csv_mimic_json["data"] << mimic_row
        break if (i+1) >= default_page_size # json response will contain only 1 page of data
      end
      assert_equal json_response, csv_mimic_json
    end
  end


  test "API projects/:id/tables/:table_ref/data?[field=value] - field=value queries are working" do
    @uploads.each do |upl|
      mapped_col_types = map_datapackage_column_types(@datapackage, upl + ".csv")

      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object
    

      csv_table.headers.each_with_index do |col,i|

        # Get indices of rows with non-empty values then pick one at random
        # Query API using each the cell value and check that returned JSON matches our selected CSV row
        non_empty_indices = []
        csv_table.by_col[i].collect.with_index {|e,j| non_empty_indices << j if !e.nil?}
        random_row_num = non_empty_indices.sample
        random_row_data = csv_table[random_row_num].fields

        get :index, :id => @project.id, :table_ref => upl, (col + "_eq").to_sym => random_row_data[i]
        json_response = JSON.parse(response.body)
        binding.pry
      end

    end
  end


  test "API projects/:id/tables/:table_ref/data - response should contain link headers" do
    skip
  end

  test "API projects/:id/tables/:table_ref/data - response should contain Records-Per-Page and Records-Total headers" do
    skip
  end

  test "API projects/:id/tables/:table_ref/data - response should contain CORS header" do
    skip
  end

end
