require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    sign_in_as @admin
    @setting = settings(:one)
  end

  test "should get index" do
    get admin_settings_url
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_setting_url(@setting)
    assert_response :success
  end

  test "should update setting" do
    patch admin_setting_url(@setting), params: { setting: { value: "New value" } }
    assert_redirected_to admin_settings_url
  end
end
