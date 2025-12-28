require "test_helper"

class Admin::InviteLinksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_invite_links_index_url
    assert_response :success
  end

  test "should get create" do
    get admin_invite_links_create_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_invite_links_destroy_url
    assert_response :success
  end
end
