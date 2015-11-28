require 'test_helper'

class ProjectsControllerUploadDatasourceTest < ActionController::TestCase

  setup do
    @controller = ProjectsController.new # this is needed because we don't have a separate controller for datapackage!
                                         # See http://stackoverflow.com/a/7743176. The tests work in isolation, but
                                         # get errors when all tests run together.
    sign_in users(:one)
    @user = users(:one)
    @project = @user.projects.build(name: "Upload test project", description: "Upload test project description")
    @project.save
    upload_to_project(@project, [], "uploads/datapackage.json") # just upload datapackage file
  end

  def teardown
    Project.find(@project.id).destroy
  end

  # datasources upload
  test "should detect when nothing uploaded" do
    post :upload_datasources, id: @project.id, :datafiles => []
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:no_upload]
    assert expected_error
  end

  test "should detect when project has no datapackage" do
    p = @user.projects.build(name: "Project without datapackage", description: "Upload test project description")
    p.save
    upload = fixture_file_upload("uploads/good_upload.csv", "text/plain")
    post :upload_datasources, id: p.id, :datafiles => [upload]
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:no_datapackage]
    assert expected_error
    p.destroy
  end

  test "should detect when non-csv file uploaded" do
    txt_upload = fixture_file_upload("uploads/upload1.txt")
    post :upload_datasources, id: @project.id, :datafiles => [txt_upload]
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:non_csv]
    assert expected_error
  end

  test "should detect when project has no metadata for upload" do
    orphan_upload = fixture_file_upload("uploads/not_in_datapackage.csv")
    post :upload_datasources, id: @project.id, :datafiles => [orphan_upload]
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:no_resource_metadata]
    assert expected_error
  end

  test "should detect when no metadata for field" do
    # metadata has been uploaded. Will delete it explicitly, then upload a csv file to induce the error
    csv_upload = "upload1.csv"
    dp_resource=@project.datapackage.datapackage_resources.find{ |r| r.path == csv_upload }
    res_fields = DatapackageResourceField.where(datapackage_resource_id: dp_resource.id)
    res_fields.each { |r| r.destroy }
    good_upload = fixture_file_upload("uploads/" + csv_upload)
    post :upload_datasources, id: @project.id, :datafiles => [good_upload]
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:field_missing_metadata]
    assert expected_error
  end

  test "should detect when same file uploaded again" do
    good_upload = fixture_file_upload("uploads/upload1.csv")
    post :upload_datasources, id: @project.id, :datafiles => [good_upload]
    post :upload_datasources, id: @project.id, :datafiles => [good_upload]
    expected_error = assigns["project"].errors.messages[:csv].flatten.include? datasource_errors[:already_uploaded]
    assert expected_error
  end

  test "should set import status to error when bad file uploaded" do
    # Wasn't able to complete this test. When the import fails, it is in the middle of a database transaction.
    # Not sure what's going on but it's related to this question: http://stackoverflow.com/q/21138207/1002140
    # Can't catch the error I want to because another error crops up further on and it is due to trying to
    # execute another query on the database:
    # ActiveRecord::StatementInvalid: PG::InFailedSqlTransaction: ERROR:  current transaction is aborted, commands ignored until end of transaction block
    skip
    upl = "bad_upload.csv"
    bad_upload = fixture_file_upload("uploads/" + upl)
    assert_raises ActiveRecord::StatementInvalid do
      post :upload_datasources, id: @project.id, :datafiles => [bad_upload]
    end
    assert_equal "error",bad_datasource.import_status
  end

  test "should be able to import csv file with ID column" do
    # see with_id_column fixture.
    skip
  end

  test "should upload when all ok" do
    skip
  end

  test "should set correct datasource_id in datapackage_resource table when same file uploaded to two projects" do
    skip
  end

  test "should index column by default" do
    skip
  end

  test "should not index where field has mira['index']: false" do
    skip
  end

end
