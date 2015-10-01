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

  
  def csv_row_count(csv_file)
    row_count = File.open(csv_file,"r").readlines.size - 1
  end

  def default_page_size
    Rails.application.config.x.api_default_per_page
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

  test "API projects/:id/tables/:table_ref/data - with no query returns default number of rows" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      assert_equal [csv_row_count(csv_file),default_page_size].min, json_response["data"].length
    end
  end

  test "API projects/:id/tables/:table_ref/data - with no query returns correct variables" do
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

end
