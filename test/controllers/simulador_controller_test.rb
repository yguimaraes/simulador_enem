require 'test_helper'

class SimuladorControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
