require "test_helper"

class ShareControllerTest < ActionDispatch::IntegrationTest
  test "should get email" do
    get share_email_url
    assert_response :success
  end
end
