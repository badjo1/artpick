require "test_helper"

class Admin::ImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    sign_in_as @user
    @image = Image.create!(title: "Test Image")
  end

  test "should get index" do
    get admin_images_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_image_url
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_image_url(@image)
    assert_response :success
  end

  test "should update image" do
    patch admin_image_url(@image), params: {
      image: { title: "Updated Title" }
    }
    assert_redirected_to admin_images_url
    @image.reload
    assert_equal "Updated Title", @image.title
  end

  test "should destroy image" do
    assert_difference("Image.count", -1) do
      delete admin_image_url(@image)
    end

    assert_redirected_to admin_images_url
  end

  test "should get bulk_new" do
    get bulk_new_admin_images_url
    assert_response :success
  end

  test "should require authentication" do
    sign_out
    get admin_images_url
    assert_redirected_to new_session_url
  end
end
