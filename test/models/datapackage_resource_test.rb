require 'test_helper'

class DatapackageResourceTest < ActiveSupport::TestCase

  setup do
    @project = projects(:one)
    @datapackage = datapackages(:one)
    @datapackage_resource = DatapackageResource.new(
      datapackage_id: @datapackage.id,
      path: "test.csv",
      delimiter: ",",
      quote_character: '"',
      table_ref: "test"
    )
  end

  test "should save with all required attributes" do
    assert @datapackage_resource.save
  end

  test "should not save without a datapackage_id" do
    @datapackage_resource.datapackage_id = nil
    refute @datapackage_resource.save
  end

  test "should not save without a path" do
    @datapackage_resource.path = nil
    refute @datapackage_resource.save
  end

  test "should not save without a delimiter" do
    @datapackage_resource.delimiter = nil
    refute @datapackage_resource.save
  end

  test "should not save without a quote_character" do
    @datapackage_resource.quote_character = nil
    refute @datapackage_resource.save
  end

  test "should not save without a table_ref" do
    @datapackage_resource.table_ref = nil
    refute @datapackage_resource.save
  end


end
