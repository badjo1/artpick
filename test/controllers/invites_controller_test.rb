require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "should get show with valid token" do
    invite_link = invite_links(:one)
    get invite_url(invite_link.token)
    assert_response :redirect
  end
end
