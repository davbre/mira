require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    sign_in users(:one)
    # @project = projects(:one)

    # Delayed::Worker.delay_jobs = false # turn off queuing

    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save

  end


  # uploads
  test "should detect when no files uploaded" do
    post :upload_ds, id: @project.id, :datafiles => [ ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "you must upload one or more csv files along with their datapackage.json file"
    assert no_datapackage
  end

  test "should detect when no datapackage.json is uploaded" do

    upload1 = fixture_file_upload("uploads/upload1.csv", "text/csv")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    # datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: @project.id, :datafiles => [ upload1, upload2 ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "no datapackage.json was uploaded"
    assert no_datapackage
  end

  test "should detect when no csv files are uploaded" do

    upload1 = fixture_file_upload("uploads/upload1.txt", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.txt", "text/plain")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: @project.id, :datafiles => [ upload1, upload2, datapackage ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "no csv files were uploaded"
    assert no_datapackage

  end

  test "should detect when a non-csv/non-datapackage.json file is uploaded" do

    upload1 = fixture_file_upload("uploads/upload1.txt", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: @project.id, :datafiles => [ upload1, upload2, datapackage ]
    no_datapackage = assigns["project"].errors.messages[:uploads].include? "only csv files can be uploaded along with their datapackage.json file"
    assert no_datapackage
  end

  test "should detect when datapackage.json does not contain a resource section for each csv file" do

    upload1 = fixture_file_upload("uploads/upload1.csv", "text/plain")
    upload2 = fixture_file_upload("uploads/not_in_datapackage.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")

    # initially tried posting files but could not test as it's operating in a different thread.
    # See the following: http://stackoverflow.com/a/26721987. Instead calling the job directly instead
    # and catching the RuntimeError
    tempfile_location_hash = { } # map original filename to temporary location
    [upload1, upload2, datapackage].each { |u| tempfile_location_hash[u.original_filename] = u.tempfile }

    err = assert_raises(RuntimeError) { CheckDatapackage.new(@project.id, tempfile_location_hash).perform }
    assert_match /datapackage.json has not metadata for csv files/, err.message

  end

  test "uploaded datapackage and csv files should be saved in the public path" do

    upload1 = fixture_file_upload("uploads/upload1.csv", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")

    tempfile_location_hash = { } # map original filename to temporary location
    [upload1, upload2, datapackage].each { |u| tempfile_location_hash[u.original_filename] = u.tempfile }

    CheckDatapackage.new(@project.id, tempfile_location_hash).perform

    expected_datapackage_path = Rails.public_path.to_s + "/" + @project.datasources.where(datafile_file_name: "datapackage.json").first.public_url
    expected_csv_path1 = Rails.public_path.to_s + "/" + @project.datasources.where(datafile_file_name: "upload1.csv").first.public_url
    expected_csv_path2 = Rails.public_path.to_s + "/" + @project.datasources.where(datafile_file_name: "upload2.csv").first.public_url
    assert File.file?(expected_datapackage_path)
    assert File.file?(expected_csv_path1)
    assert File.file?(expected_csv_path2)
  end

  test "project upload folder and log file folder should exist" do

    upload1 = fixture_file_upload("uploads/upload1.csv", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")
    post :upload_ds, id: @project.id, :datafiles => [ upload1, upload2, datapackage ]
    assert Dir.exists? @project.upload_path
    assert Dir.exists? @project.job_log_path
  end



  test "on successful upload log files should exist for datapackage.json and csv files" do
    upload1 = fixture_file_upload("uploads/upload1.csv", "text/plain")
    upload2 = fixture_file_upload("uploads/upload2.csv", "text/csv")
    datapackage = fixture_file_upload("uploads/datapackage.json", "application/json")

    tempfile_location_hash = { } # map original filename to temporary location
    [upload1, upload2, datapackage].each { |u| tempfile_location_hash[u.original_filename] = u.tempfile }

    CheckDatapackage.new(@project.id, tempfile_location_hash).perform

    expected_dp_log_path = @project.job_log_path + "datapackage.json.log"
    expected_csv_log_path1 = @project.job_log_path + "/upload1.csv.log"
    expected_csv_log_path2 = @project.job_log_path + "/upload2.csv.log"

    assert File.file?(expected_dp_log_path)
    assert File.file?(expected_csv_log_path1)
    assert File.file?(expected_csv_log_path2)
  end

end
