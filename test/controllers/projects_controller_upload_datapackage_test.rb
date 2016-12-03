require 'test_helper'

class ProjectsControllerUploadDatapackageTest < ActionController::TestCase

  setup do
    @controller = ProjectsController.new # this is needed because we don't have a separate controller for datapackage!
                                         # See http://stackoverflow.com/a/7743176. The tests work in isolation, but
                                         # get errors when all tests run together.
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
  end

  # datapackage upload
  test "should detect when datapackage already uploaded" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    another_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:already_uploaded]
    assert expected_error
  end

  test "should detect when no datapackage uploaded" do
    post :upload_datapackage, id: @project.id, :datapackage => nil
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:no_upload]
    assert expected_error
  end

  test "should detect when bad json" do
    bad_json_datapackage = fixture_file_upload("uploads/datapackage/bad_not_json/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => bad_json_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:bad_json]
    assert expected_error
  end

  test "should detect when datapackage has no resources property" do
    has_no_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => has_no_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:resources_missing]
  end

  test "should detect when datapackage resources property is not an array" do
    non_array_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_not_array/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => non_array_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:non_array_resources]
  end

  test "should detect when datapackage resources property is missing" do
    empty_resources_dp = fixture_file_upload("uploads/datapackage/bad_resources_empty/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => empty_resources_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:resources_missing]
  end

  test "should detect when individual resource metadata is not a hash" do
    # @datapackage_errors:
    #   resource_not_hash: "resource metadata must be a hash.",
    skip
  end

  test "should detect when path is missing" do
    no_path_datapackage = fixture_file_upload("uploads/datapackage/bad_path_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_path_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_path]
    assert expected_error
  end

  test "when 'schema' is a string should detect when 'schemas' hash is missing" do
    # @datapackage_errors:
    # schemas_missing: "Expected a 'schemas' hash as 'schema' string is given.",
    skip
  end

  test "should detect when schema is missing" do
    no_schema_datapackage = fixture_file_upload("uploads/datapackage/bad_schema_missing/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => no_schema_datapackage
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:missing_schema]
    assert expected_error
  end

  test "should detect when path is not a String" do
    not_string_path_dp = fixture_file_upload("uploads/datapackage/bad_path_not_string/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => not_string_path_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_not_string]
    assert expected_error
  end

  test "should detect when path is empty" do
    empty_path_dp = fixture_file_upload("uploads/datapackage/bad_path_empty/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => empty_path_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_empty]
    assert expected_error
  end

  test "should detect when path does not refer to a csv file" do
    path_not_csv_dp = fixture_file_upload("uploads/datapackage/bad_path_not_csv/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => path_not_csv_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:path_not_csv]
    assert expected_error
  end

  test "should detect when schema is not a Hash" do
    schema_not_hash_dp = fixture_file_upload("uploads/datapackage/bad_schema_not_hash/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_not_hash_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_not_hash]
    assert expected_error
  end

  test "should detect when schema has no fields" do
    schema_no_fields_dp = fixture_file_upload("uploads/datapackage/bad_schema_no_fields/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_no_fields_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_no_fields]
    assert expected_error
  end

  test "should detect when schema fields is not an Array" do
    schema_not_array_dp = fixture_file_upload("uploads/datapackage/bad_schema_not_array/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => schema_not_array_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:schema_not_array]
    assert expected_error
  end

  test "should detect when a schema field does not have both a name and a type" do
    field_not_name_and_type_dp = fixture_file_upload("uploads/datapackage/bad_field_not_name_and_type/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => field_not_name_and_type_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_not_name_and_type]
    assert expected_error
  end

  test "should detect invalid field name" do

    skip # this is no longer valid as the parameterize method is used to change the column name to be more database friendly

    # field_invalid_name_dp = fixture_file_upload("uploads/datapackage/bad_field_invalid_name/datapackage.json", "application/json")
    # post :upload_datapackage, id: @project.id, :datapackage => field_invalid_name_dp
    # expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_invalid_name]
    # assert expected_error
  end

  test "should detect invalid field type" do
    field_invalid_type_dp = fixture_file_upload("uploads/datapackage/bad_field_invalid_type/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => field_invalid_type_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:field_invalid_type]
    assert expected_error
  end

  # datapackage database table insertion
  test "bad datapackage should not add record to datapackage datapackage_resource or datapackage_resource_field tables" do
    # upload bad datapackage. Observation counts should be the same after as before.
    bad_datapackage = fixture_file_upload("uploads/datapackage/bad_not_json/datapackage.json", "application/json")
    before_dp_count = Datapackage.count
    before_dp_res_count = DatapackageResource.count
    before_dp_res_fld_count = DatapackageResourceField.count
    post :upload_datapackage, id: @project.id, :datapackage => bad_datapackage
    assert_equal before_dp_count, Datapackage.count
    assert_equal before_dp_res_count, Datapackage.count
    assert_equal before_dp_res_fld_count, Datapackage.count
  end

  test "good datapackage should add record correctly to datapackage table" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    assert_difference('Datapackage.count',1) do
      post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    end
    last_dp = Datapackage.last
    assert_equal @project.id, last_dp.project_id
    assert_equal "/uploads/project_" + @project.id.to_s + "/datapackage.json", last_dp.public_url
    assert_equal "datapackage.json", last_dp.datapackage_file_name
  end

  test "good datapackage should add rows correctly to datapackage_resources table" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    before_dp_res_count = DatapackageResource.count
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    dp_json = JSON.parse(File.read(good_datapackage))
    dp_json_resource_names = dp_json["resources"].map { |r| r["path"] }
    # correct number of resources added to DB table
    assert_equal dp_json["resources"].length + before_dp_res_count, DatapackageResource.count
    # each new resource has correct path
    assert_equal dp_json_resource_names.sort, Project.find(@project.id).datapackage.datapackage_resources.map { |r| r["path"] }.sort
    # table_ref as expected
    assert_equal dp_json_resource_names.map { |r| r.split(".").first }.sort, Project.find(@project.id).datapackage.datapackage_resources.map { |r| r["table_ref"] }.sort
    # delimiter and quote character are populated in all new resources
    assert_equal false, Project.find(@project.id).datapackage.datapackage_resources.map { |r| r["delimiter"] }.include?(nil)
    assert_equal false, Project.find(@project.id).datapackage.datapackage_resources.map { |r| r["quote_character"] }.include?(nil)
  end

  test "good datapackage should add rows correctly to datapackage_resource_fields table" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    before_dp_res_field_count = DatapackageResourceField.count
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    dp_json = JSON.parse(File.read(good_datapackage))
    # correct number of resource fields added to DB table
    new_field_count = 0
    @project.datapackage.datapackage_resources.each do |res|
      dp_json_res = dp_json["resources"].find{ |r| r["path"] == res.path }
      # same number of fields
      assert_equal dp_json_res["schema"]["fields"].length, res.datapackage_resource_fields.length
      # same field name, type and order
      dp_json_res["schema"]["fields"].each_with_index do |f,ndx|
        db_field = res.datapackage_resource_fields.select{|s| s.name == f["name"]}.first
        assert_not_nil db_field
        assert_equal ndx + 1, db_field.order
        assert_equal f["name"], db_field.name
        assert_equal f["type"], db_field.ftype
      end
      # keep count of fields for last test
      new_field_count += dp_json_res["schema"]["fields"].length
    end
    assert_equal before_dp_res_field_count + new_field_count, DatapackageResourceField.count
  end

  test "good datapackage should create database table with correct name, columns, types and indices" do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    last_dp = Datapackage.last
    dp_resources = last_dp.datapackage_resources
    dp_resources.each do |dp_res|
      # database table exists
      expected_db_table_name = Rails.configuration.x.db_table_prefix.downcase + last_dp.project_id.to_s + "_" + dp_res.id.to_s
      ar_table = Mira::Application.const_get(expected_db_table_name.capitalize.to_sym)
      assert ActiveRecord::Base.connection.table_exists? expected_db_table_name
      # database table has correct columns
      expected_db_table_columns = dp_res.datapackage_resource_fields.map { |f| f.name } | ["id"] # add "id" if not already there
      expected_db_table_columns = expected_db_table_columns + MIRA_EXTRA_VARIABLE_MAP.keys
      actual_columns = ar_table.columns.map { |c| c.name }
      assert_equal expected_db_table_columns.sort, actual_columns.sort
      # database table column types are as expected
      expected_column_types = {"id" => "integer"}.merge(MIRA_EXTRA_VARIABLE_MAP)
      # binding.pry
      # dp_res.datapackage_resource_fields.map { |f| expected_column_types << {f.name => DATAPACKAGE_TYPE_MAP[f.ftype] } }
      dp_res.datapackage_resource_fields.each {|x| expected_column_types[x.name] = DATAPACKAGE_TYPE_MAP[x.ftype]}
      actual_column_types = {}
      ar_table.columns.each { |x| actual_column_types[x.name] = x.type.to_s }
      assert_equal expected_column_types, actual_column_types
      # database table indices as expected
      # **NOTE ON INDICES**: couldn't get this test to work. Although the index seems to be created (when viewing from phppgadmin)
      # when I try to get a list of indices, indices on string columns are not returned. Not sure why so going to
      # skip this for the moment
      table_indices = ActiveRecord::Base.connection.indexes(ar_table.name.downcase.to_sym)
      # One option with raw query: http://stackoverflow.com/a/2213199/1002140
      # rq = "select i.relname as index_name, a.attname as column_name
      #       from pg_class t,pg_class i,pg_index ix, pg_attribute a
      #       where t.oid = ix.indrelid and i.oid = ix.indexrelid
      #             and a.attrelid = t.oid and a.attnum = ANY(ix.indkey)
      #             and t.relkind = 'r' and t.relname = '*** YOUR TABLE NAME ***'
      #             order by t.relname, i.relname;"
      # results = ActiveRecord::Base.connection.execute(rq)
      # dp_res_fields = dp_res.datapackage_resource_fields.map { .... add_index field... }
    end
  end

  test "should detect a delimiter of more than a single character" do
    long_dlm_dp = fixture_file_upload("uploads/datapackage/bad_delimiter_too_long/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => long_dlm_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:delimiter_too_long]
  end

  test "should be able to save tab character in the delimiter field " do
    good_datapackage = fixture_file_upload("uploads/datapackage/good/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => good_datapackage
    tabbed_resource = @project.datapackage.datapackage_resources.where(table_ref: "good_upload_with_tabs").first
    assert_equal "\t", tabbed_resource.delimiter
  end

  test "should detect a quote character of more than a single character" do
    long_quote_dp = fixture_file_upload("uploads/datapackage/bad_quote_char_too_long/datapackage.json", "application/json")
    post :upload_datapackage, id: @project.id, :datapackage => long_quote_dp
    expected_error = assigns["project"].errors.messages[:datapackage].flatten.include? datapackage_errors[:quote_char_too_long]
  end

  test "should index column by default" do
    # see **NOTE ON INDICES** above
    skip
  end

  test "should not index where field has mira['index']: false" do
    skip
  end

  test "API should be available on successful upload" do
    skip
  end

  test "should keep only the filename from the path value" do
    # i.e. only keep "keepme.csv" from /do/not/keep/this/keepme.csv
    skip
  end

  test "should save format properly from datapackage.json" do
    skip
  end

  test "should save add_index properly" do
    skip
  end

  test "should save datapackage resource description if provided" do
    skip
  end

  test "should detect duplicate column names where case is irrelevant" do
    # I think this test would currently fail
    # MY_VARIABLE should equal My_Variable and this should not be allowed
    # as the variable names are 'parameterized' prior to going into the database
    skip
  end
end
