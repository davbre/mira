require 'test_helper'

class ProjectTest < ActiveSupport::TestCase

  test "should not save without a user" do
    # user = users(:one)
    # project = user.project.build(
    project = Project.new(name: "No user project", description: "No user project description")
    assert_not project.save
  end

  test "should save with a user, unique name and a description" do
    user = users(:one)
    project = user.projects.build(name: "Unique name", description: "Test project description")
    assert project.save
  end

  test "should not save without a project name" do
    user = users(:one)
    project = user.projects.build(name: "", description: "Test project description")
    assert_not project.save
  end

  test "should not save with a name length > 64" do
    user = users(:one)
    name65 = "a" * 65
    project = user.projects.build(name: name65, description: "Test project description")
    assert_not project.save
  end

  test "should not save with non-unique name" do
    user = users(:one)
    project1 = user.projects.build(name: "Duplicate", description: "Test project description")
    project2 = user.projects.build(name: "Duplicate", description: "Test project description")
    project1.save
    assert_not project2.save
  end

  test "should save with unique name and no description" do
    user = users(:one)
    project = user.projects.build(name: "Unique name", description: "")
    assert project.save
  end

end
