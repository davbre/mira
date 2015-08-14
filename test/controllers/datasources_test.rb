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
end
