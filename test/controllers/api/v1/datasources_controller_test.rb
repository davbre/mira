require 'test_helper'
# require_relative '../../app/controllers/api/v1/projects_controller'
# require 'minitest/spec'

class Api::V1::DatasourcesControllerTest < ActionController::TestCase

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

    @uploads = ["upload1", "upload2"]

    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ds = @project.datasources.create(datafile: csv_file, datafile_file_name: upl + ".csv", datapackage_id: @dp.id) 
      ds.save
      ds.db_table_name = Rails.configuration.x.db_table_prefix.downcase + ds.project_id.to_s + "_" + ds.id.to_s
      ds.save

      ProcessCsvUpload.new(ds.id,@datapackage).perform

    end
  end



  # api/project/:id/tables
  test "API projects/:id/tables - response ok" do
    get :index, :id => @project.id
    assert_response :success
  end  

  test "API projects/:id/tables - response contains same number of uploads" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    assert json_response.length == @uploads.length
  end  

  test "API projects/:id/tables - response contains each upload" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      refute_nil upload_csv_search
    end
  end  

  test "API's projects/:id/tables - each upload contains reference to correct datapackage" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert upload_csv_search["datapackage_id"] == @dp.id
    end
  end

  test "API's projects/:id/tables - each upload references expected database table name" do
    get :index, :id => @project.id
    json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      upload_csv_search = json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert upload_csv_search["db_table_name"] == Rails.configuration.x.db_table_prefix.downcase + \
                                                  @project.id.to_s + "_" + upload_csv_search["id"].to_s
    end
  end


  # api/project/:id/tables/:table_ref
  test "API projects/:id/tables/:table_ref - response ok" do
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      assert_response :success
    end
  end

  # this test saves from repeating the group tests on the individual table endpoints
  test "API projects/:id/tables/:table_ref - table details same from individual and group endpoints" do
    get :index, :id => @project.id
    all_tables_json_response = JSON.parse(response.body)
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      individual_table_json_response = JSON.parse(response.body)
      group_csv_search = all_tables_json_response.detect{ |a| a["datafile_file_name"] == upl + ".csv" }
      assert_equal group_csv_search, individual_table_json_response.except("row_count") # except is rails method
    end
  end

  test "API projects/:id/tables/:table_ref - returns correct row count" do # row count only appears in the individual table endpoint
    @uploads.each do |upl|
      get :show, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      row_count = File.open(csv_file,"r").readlines.size
      assert_equal row_count, json_response["row_count"] + 1 # extra 1 accounts for header row
    end
  end


  # api/projects/:id/tables/:table_ref/columns
  test "API projects/:id/tables/:table_ref/columns - returns correct columns" do
    @uploads.each do |upl|
      get :column_index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_header_columns = CSV.open(csv_file, 'r') { |csv| csv.first } # http://stackoverflow.com/a/18113090/1002140
      json_columns = json_response.except("id").keys # remove id before assert equal
      assert_equal csv_header_columns, json_columns
    end
  end

  test "API projects/:id/tables/:table_ref/columns - returns correct column metadata" do
    @uploads.each do |upl|
      get :column_index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      mapped_col_types = map_datapackage_column_types(@datapackage, upl + ".csv")
      assert_equal mapped_col_types, json_response.except("id")
    end
  end

  # api/projects/:id/tables/:table_ref/columns/:col_ref
  test "API projects/:id/tables/:table_ref/columns/:col_ref - returns correct column + metadata" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_header_columns = CSV.open(csv_file, 'r') { |csv| csv.first } # http://stackoverflow.com/a/18113090/1002140

      mapped_col_types = map_datapackage_column_types(@datapackage, upl + ".csv")

      csv_header_columns.each do |col|
        get :column_show, :id => @project.id, :table_ref => upl, :col_ref => col
        json_response = JSON.parse(response.body)
        assert_equal col, json_response["name"]
        assert_equal mapped_col_types[col], json_response["type"]
      end
    end
  end



end
