require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get invites_show_url
    assert_response :success
  end
end
