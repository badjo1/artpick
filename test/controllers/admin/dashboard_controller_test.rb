require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in_as @admin
  end

  test "should get index" do
    get admin_root_url
    assert_response :success
  end
end
