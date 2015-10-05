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



  def csv_row_to_json(datapackage_upload_name,id,row) # row is CSV row object
    mapped_col_types = map_datapackage_column_types(@datapackage, datapackage_upload_name)
    mimic_json = { "id" => id }
    row_as_hash = row.to_hash
    row_as_hash.each do |cell|
      cell_typed = cell_to_type(cell,mapped_col_types)
      mimic_json[cell[0]] = cell_typed
    end
    mimic_json
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


  test "API projects/:id/tables/:table_ref/data?[field=value] - field=value queries are working" do
    @uploads.each do |upl|
      mapped_col_types = map_datapackage_column_types(@datapackage, upl + ".csv")

      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object
    

      csv_table.headers.each_with_index do |col,i|


        # '_blank' assert response has same number of rows with blank column as does the csv (not checking data)
        # re-read csv file here as was unable to clone and subset csv_table
        blank_csv = CSV.read(csv_file, headers: true).delete_if { |r| r[col] != nil }
        get :index, :id => @project.id, :table_ref => upl, (col + "_blank").to_sym => nil # "_blank" scopes have no value, so use nil here
        json_response = JSON.parse(response.body)
        binding.pry
       # filter( options = Hash.new ) { |row| ... }
      end

    end
  end

end
