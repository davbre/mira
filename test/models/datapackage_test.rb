require 'test_helper'

class DatapackageTest < ActiveSupport::TestCase

  setup do
    @project = projects(:one)
  end

  test "should not save without a project_id" do
    datapackage = Datapackage.new
    assert_not datapackage.save
  end

  test "should save with a user and a project id" do
    datapackage = Datapackage.new(project_id: @project.id)
    assert datapackage.save
  end

  # Want to enforce that there can only be one datapackage per project. It
  # seems you can't enforce this at the database level. So will cover in the
  # controller.

end
