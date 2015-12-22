require 'test_helper'

class Api::V1::DataControllerTest < ActionController::TestCase

  include Devise::TestHelpers


  setup do
    sign_in users(:one)
    # @project = projects(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    @uploads = ["good_upload"]
    upload_to_project(@controller,@project, @uploads, "uploads/datapackage/good/datapackage.json") # just upload datapackage file
    @dp_file_json = JSON.parse(File.read(@dp_file))
  end


  def csv_row_to_json(datapackage_upload_name,id,row) # row is CSV row object
    mapped_col_types = map_datapackage_column_types(@dp_file_json, datapackage_upload_name)
    mimic_json = { "id" => id }
    row_as_hash = row.to_hash
    row_as_hash.each do |cell|
      cell_typed = cell_to_type(cell,mapped_col_types)
      mimic_json[cell[0]] = cell_typed
    end
    mimic_json
  end

  def csv_column_type(csv_upload_name, column)
    mapped_col_types = map_datapackage_column_types(@dp_file_json, csv_upload_name)
    mapped_col_types[column]
  end

  # HTTP JSON: {"id"=>1, "name"=>"John", "age"=>23, "dob"=>"2015-12-01", "score"=>12.145, "longid"=>1000000000000000000, "boolfl"=>true}
  # CSV File:  {"name"=>"John", "age"=>"23", "dob"=>"2015-12-01", "score"=>"12.145", "longid"=>"1000000000000000000", "boolfl"=>"TRUE"}
  # Type map:  {"name"=>"text", "age"=>"integer", "dob"=>"date", "score"=>"float", "longid"=>"integer", "boolfl"=>"boolean"}
  def cell_to_type(text_cell,type_map)
    # text_cell will look like ["column_name", "column_value"]
    # type_map will look like {"column_name"=>"column_type", ... }
    ret = nil
    cell_type = type_map[text_cell[0]]
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

  test "API request for page of data returns default number of rows" do
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
      assert_equal csv_header_columns.sort, (column_counts.keys - ["id"]).sort
    end
  end


  test "API projects/:id/tables/:table_ref/data - returns correct values in every cell" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object
      get :index, :id => @project.id, :table_ref => upl
      json_response = JSON.parse(response.body)
      # replace any missing values with nil. This is a hack but is needed because values can be either missing or null
      json_response["data"].each do |jrow|
        jrow.update(jrow){|key,v1| (v1 == "") ? nil : v1 }
      end
      # mimics the json response using csv file, then compare the two
      csv_mimic_json = { "data" => []}
      csv_table.each_with_index do |row,i|
        csv_mimic_json["data"] << csv_row_to_json(upl  + ".csv",i+1,row)
        break if (i+1) >= default_page_size # json response will contain only 1 page of data
      end
      assert_equal json_response, csv_mimic_json
    end
  end


  test "API projects/:id/tables/:table_ref/data?[field] '_eq' and '_ne' queries are working" do
    @uploads.each do |upl|

      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object

      csv_table.headers.each_with_index do |col,i|

        # Get indices of rows with non-empty values then pick one at random
        # Query API using each the cell value and check that returned JSON matches our selected CSV row
        column_values = csv_table.by_col[i]
        non_empty_indices = column_values.each_with_index.map {|e,j| e.present? ? j : nil }.compact
        random_row_num = non_empty_indices.sample
        random_csv_row_json = csv_row_to_json(upl  + ".csv",random_row_num + 1,csv_table[random_row_num])

        # "_eq" assert response has row
        get :index, :id => @project.id, :table_ref => upl, (col + "_eq").to_sym => random_csv_row_json[col]
        json_response = JSON.parse(response.body)
        json_response_row = json_response["data"].detect { |e| e["id"] == random_row_num + 1 }
        # replace any missing values with nil. This is a hack but is needed because values can be either missing or null
        json_response_row.update(json_response_row){|key,v1| (v1 == "") ? nil : v1 }

        assert_equal random_csv_row_json, json_response_row

        # "_ne" assert response does not have row
        get :index, :id => @project.id, :table_ref => upl, (col + "_ne").to_sym => random_csv_row_json[col]
        json_response = JSON.parse(response.body)
        json_response_row = json_response["data"].detect { |e| e["id"] == random_row_num + 1 }
        assert_nil json_response_row

      end

    end
  end

  test "'_blank' and '_not_blank' queries are working" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object

      csv_table.headers.each_with_index do |col,i|
        # '_blank' assert response has same number of rows with blank column as does the csv (not checking data)
        # re-read csv file here as was unable to clone and subset csv_table
        blank_csv = CSV.read(csv_file, headers: true).delete_if { |r| r[col] != nil && r[col] != ""}
        get :index, :id => @project.id, :table_ref => upl, (col + "_blank").to_sym => nil # "_blank" scopes have no value, so use nil here
        json_response = JSON.parse(response.body)
        assert_equal json_response["data"].length, blank_csv.count
      end

      csv_table.headers.each_with_index do |col,i|
        # '_not_blank' assert response has same number of rows with non-blank column as does the csv (not checking data)
        # re-read csv file here as was unable to clone and subset csv_table
        blank_csv = CSV.read(csv_file, headers: true).delete_if { |r| r[col] == nil || r[col] == '' }
        get :index, :id => @project.id, :table_ref => upl, (col + "_not_blank").to_sym => nil, :per_page => 100
        json_response = JSON.parse(response.body)
        assert_equal json_response["data"].length, blank_csv.count
      end
    end
  end


  test "_lt _le _gt _ge queries are working" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")
      csv_table = CSV.read(csv_file, headers: true) # read in whole file, returns a CSV::Table object
      # expects a row in csv file with name = "Middle-of-the-road" !
      middling_row = csv_table.find { |a| a["name"] == "Middle-of-the-road" }

      csv_table.headers.each_with_index do |col,i|
        col_type = csv_column_type(upl + ".csv", col)

        unless col_type == "boolean"

          # _lt
          filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
            (["integer", "float"].exclude? col_type and (r[col] == nil or r[col] >= middling_row[col]))  \
               || (["integer", "float"].include? col_type and (r[col] == nil or r[col].to_f >= middling_row[col].to_f))
          }
          get :index, :id => @project.id, :table_ref => upl, (col + "_lt").to_sym => middling_row[col], :per_page => 100
          json_response = JSON.parse(response.body)
          assert_equal json_response["data"].length, filtered_csv.count


          # _le
          filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
            (["integer", "float"].exclude? col_type and (r[col] == nil or r[col] > middling_row[col]))  \
               || (["integer", "float"].include? col_type and (r[col] == nil or r[col].to_f > middling_row[col].to_f))
          }
          get :index, :id => @project.id, :table_ref => upl, (col + "_le").to_sym => middling_row[col], :per_page => 100
          json_response = JSON.parse(response.body)
          assert_equal json_response["data"].length, filtered_csv.count


          # _gt
          filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
            (["integer", "float"].exclude? col_type and (r[col] == nil or r[col] <= middling_row[col]))  \
               || (["integer", "float"].include? col_type and (r[col] == nil or r[col].to_f <= middling_row[col].to_f))
          }
          get :index, :id => @project.id, :table_ref => upl, (col + "_gt").to_sym => middling_row[col], :per_page => 100
          json_response = JSON.parse(response.body)
          assert_equal json_response["data"].length, filtered_csv.count


          # _ge
          filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
            (["integer", "float"].exclude? col_type and (r[col] == nil or r[col] < middling_row[col]))  \
               || (["integer", "float"].include? col_type and (r[col] == nil or r[col].to_f < middling_row[col].to_f))
          }
          get :index, :id => @project.id, :table_ref => upl, (col + "_ge").to_sym => middling_row[col], :per_page => 100
          json_response = JSON.parse(response.body)
          assert_equal json_response["data"].length, filtered_csv.count
        end

      end
    end
  end



  test "begins, not_begins queries are working" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      begins_text = "principio"

      # begins
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and r["name"].starts_with? begins_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_begins => begins_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count


      # not begins
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and !r["name"].starts_with? begins_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_not_begins => begins_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count
    end
  end


  test "ends, not_ends queries are working" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      ends_text = "fin"

      # ends
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and r["name"].ends_with? ends_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_ends => ends_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count


      # not ends
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and !r["name"].ends_with? ends_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_not_ends => ends_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count
    end
  end


  test "contains, not_contains queries are working" do
    @uploads.each do |upl|
      csv_file = fixture_file_upload("uploads/" + upl + ".csv", "text/plain")

      contains_text = "tiene"

      # contains
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and r["name"].include? contains_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_contains => contains_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count


      # not contains
      filtered_csv = CSV.read(csv_file, headers: true).delete_if { |r|
        (!r["name"].nil? and !r["name"].include? contains_text) ? false : true
      }
      get :index, :id => @project.id, :table_ref => upl, :name_not_contains => contains_text, :per_page => 100
      json_response = JSON.parse(response.body)
      assert_equal json_response["data"].length, filtered_csv.count

    end
  end


  test "should return paged distinct values for string columns" do
    upl = @uploads.first
    get :distinct, :id => @project.id, :table_ref => upl, :col_ref=> "name"
    json_response = JSON.parse(response.body)
    assert_equal Array, json_response.class
    assert_equal Rails.configuration.x.api_default_per_page, json_response.length
    assert response.header.has_key? "Link" # i.e. has header relating to paging
  end


  test "should not return distinct values for non-string columns" do
    upl = @uploads.first
    get :distinct, :id => @project.id, :table_ref => upl, :col_ref=> "age"
    json_response = JSON.parse(response.body)
    assert_equal Hash, json_response.class # The response to a valid distinct request will be an array. Otherwise it will be a Hash with a message.
  end


  test "response to data request should contain link headers" do
    upl = @uploads.first
    get :index, :id => @project.id, :table_ref => upl
    link_header = response.header["Link"]
    assert_not_nil link_header # i.e. has header relating to paging
    assert link_header.include? "\"last\""
    assert link_header.include? "\"next\""
  end

  test "response to data request should contain should contain Records-Per-Page and Records-Total headers" do
    upl = @uploads.first
    upl_row_count = File.open("test/fixtures/uploads/" + upl + ".csv","r").readlines.size - 1
    get :index, :id => @project.id, :table_ref => upl
    assert response.header.has_key? "Records-Per-Page"
    assert response.header.has_key? "Records-Total"
    assert_equal Rails.configuration.x.api_default_per_page, response.header["Records-Per-Page"].to_i
    assert_equal upl_row_count, response.header["Records-Total"].to_i
  end

  test "should be able to query project metadata" do
    skip
  end
  # can't test this locally
  # test "API projects/:id/tables/:table_ref/data - response should contain CORS header" do
  #   skip
  # end

end
