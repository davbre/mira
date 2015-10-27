require 'test_helper'

class DatapackageResourceFieldTest < ActiveSupport::TestCase

  setup do
    @datapackage_resource = datapackage_resources(:one)
    @datapackage_resource_field = DatapackageResourceField.new(
      datapackage_resource_id: @datapackage_resource.id,
      ftype: "integer",
      name: "testvar",
      order: 1
    )
  end

  test "should save with all required attributes" do
    assert @datapackage_resource_field.save
  end

  test "should not save without a datapackage_resource_id" do
    @datapackage_resource_field.datapackage_resource_id = nil
    refute @datapackage_resource_field.save
  end

  test "should not save without a ftype" do
    @datapackage_resource_field.ftype = nil
    refute @datapackage_resource_field.save
  end

  test "should not save without a name" do
    @datapackage_resource_field.name = nil
    refute @datapackage_resource_field.save
  end

  test "should not save without a order" do
    @datapackage_resource_field.order = nil
    refute @datapackage_resource_field.save
  end

  test "should not save two fields with the same order" do
    @datapackage_resource_field.save
    same_order = @datapackage_resource_field.order
    field2 = DatapackageResourceField.new(
       datapackage_resource_id: @datapackage_resource.id,
       ftype: "string",
       name: "another_testvar",
       order: same_order)
    refute field2.save
  end

end
