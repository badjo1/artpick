require "test_helper"

class ShareControllerTest < ActionDispatch::IntegrationTest
  test "should post email" do
    post share_email_url, params: {
      email: "test@example.com",
      artwork_ids: [artworks(:one).id, artworks(:two).id]
    }
    assert_response :redirect
  end
end
