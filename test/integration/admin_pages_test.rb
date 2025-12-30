require "test_helper"

class AdminPagesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  test "admin dashboard is accessible" do
    sign_in_as(@admin)
    get admin_root_path
    assert_response :success
  end

  test "admin exhibitions index is accessible" do
    sign_in_as(@admin)
    get admin_exhibitions_path
    assert_response :success
  end

  test "admin artists index is accessible" do
    sign_in_as(@admin)
    get admin_artists_path
    assert_response :success
  end

  test "admin spaces index is accessible" do
    sign_in_as(@admin)
    get admin_spaces_path
    assert_response :success
  end

  test "admin analytics is accessible" do
    sign_in_as(@admin)
    get admin_analytics_path
    assert_response :success
  end

  test "admin pages redirect to login when not authenticated" do
    get admin_root_path
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "admin pages deny access for non-admin users" do
    regular_user = User.create!(
      email_address: "regular@test.com",
      password: "password",
      role: "artfriend"
    )

    sign_in_as(regular_user)
    get admin_root_path
    assert_response :redirect
    assert_redirected_to root_path
  end
end
