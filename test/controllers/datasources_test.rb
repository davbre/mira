require 'test_helper'

class DatasourcesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    sign_in users(:one)    
    @project = projects(:one)
  end

  test "should log errors when wrong mime-type detected (use airport-codes.csv which contains html" do
    skip
  end

  test "single and double quoting characters in upload" do
    skip
  end

  test "should not return distinct values for non-text/string columns" do
    skip
  end

  test "should return a message in json saying distinct values not supported for column when not text/string" do
    skip
  end

  test "should return paged distinct values for text/string columns" do
    skip
  end

end
