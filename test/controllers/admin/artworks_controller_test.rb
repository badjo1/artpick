require "test_helper"

class Admin::ArtworksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    sign_in_as @user
    @exhibition = exhibitions(:one)
    @artwork = artworks(:one)

    # Attach a test file to the artwork for tests that need it
    @artwork.file.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )
  end

  test "should get index" do
    get admin_exhibition_artworks_url(@exhibition)
    assert_response :success
  end

  test "should get new" do
    get new_admin_exhibition_artwork_url(@exhibition)
    assert_response :success
  end

  test "should create artwork" do
    assert_difference('Artwork.count') do
      post admin_exhibition_artworks_url(@exhibition), params: {
        artwork: {
          title: 'New Test Artwork',
          description: 'Test description',
          file: fixture_file_upload('test_image.jpg', 'image/jpeg')
        }
      }
    end

    assert_redirected_to admin_exhibition_artworks_url(@exhibition)
    assert_equal 'Artwork created successfully', flash[:notice]
  end

  test "should not create artwork without title" do
    assert_no_difference('Artwork.count') do
      post admin_exhibition_artworks_url(@exhibition), params: {
        artwork: {
          title: ''
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_admin_exhibition_artwork_url(@exhibition, @artwork)
    assert_response :success
  end

  test "should update artwork title" do
    patch admin_exhibition_artwork_url(@exhibition, @artwork), params: {
      artwork: { title: "Updated Title" }
    }

    assert_redirected_to admin_exhibition_artworks_url(@exhibition)
    @artwork.reload
    assert_equal "Updated Title", @artwork.title
    assert_equal 'Artwork updated successfully', flash[:notice]
  end

  test "should update artwork description" do
    patch admin_exhibition_artwork_url(@exhibition, @artwork), params: {
      artwork: { description: "Updated description" }
    }

    assert_redirected_to admin_exhibition_artworks_url(@exhibition)
    @artwork.reload
    assert_equal "Updated description", @artwork.description
  end

  test "should not update artwork with blank title" do
    original_title = @artwork.title

    patch admin_exhibition_artwork_url(@exhibition, @artwork), params: {
      artwork: { title: '' }
    }

    assert_response :unprocessable_entity
    @artwork.reload
    assert_equal original_title, @artwork.title
  end

  test "should destroy artwork" do
    assert_difference("Artwork.count", -1) do
      delete admin_exhibition_artwork_url(@exhibition, @artwork)
    end

    assert_redirected_to admin_exhibition_artworks_url(@exhibition)
    assert_equal 'Artwork deleted successfully', flash[:notice]
  end

  test "should update exhibition artwork_count after destroy" do
    initial_count = @exhibition.artworks.count

    delete admin_exhibition_artwork_url(@exhibition, @artwork)

    @exhibition.reload
    assert_equal initial_count - 1, @exhibition.artwork_count
  end

  test "should get bulk_new" do
    get bulk_new_admin_exhibition_artworks_url(@exhibition)
    assert_response :success
  end

  test "should require authentication" do
    sign_out
    get admin_exhibition_artworks_url(@exhibition)
    assert_redirected_to new_session_url
  end
end
