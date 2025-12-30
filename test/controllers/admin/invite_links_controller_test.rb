require "test_helper"

class Admin::InviteLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in_as @admin
    @invite_link = invite_links(:one)
  end

  test "should get index" do
    get admin_invite_links_url
    assert_response :success
  end

  test "should create invite link" do
    assert_difference("InviteLink.count") do
      post admin_invite_links_url, params: { invite_link: { name: "Test Invite" } }
    end
    assert_redirected_to admin_invite_links_url
  end

  test "should destroy invite link" do
    assert_difference("InviteLink.count", -1) do
      delete admin_invite_link_url(@invite_link)
    end
    assert_redirected_to admin_invite_links_url
  end
end
