require 'test_helper'

class Admin::ExhibitionMediaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update(role: 'admin')
    sign_in_as @user

    @exhibition = exhibitions(:one)
    @test_image_path = Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')
  end

  # Index tests
  test 'should get index' do
    get admin_exhibition_exhibition_media_url(@exhibition)
    assert_response :success
  end

  test 'should get index with slug' do
    get admin_exhibition_exhibition_media_url(@exhibition.slug)
    assert_response :success
  end

  # New tests
  test 'should get new' do
    get new_admin_exhibition_exhibition_medium_url(@exhibition)
    assert_response :success
  end

  test 'should get new with slug' do
    get new_admin_exhibition_exhibition_medium_url(@exhibition.slug)
    assert_response :success
  end

  # Create (single upload) tests
  test 'should create exhibition medium' do
    assert_difference('ExhibitionMedium.count') do
      post admin_exhibition_exhibition_media_url(@exhibition), params: {
        exhibition_medium: {
          file: fixture_file_upload('test_image.jpg', 'image/jpeg'),
          caption: 'Test photo',
          photographer: 'Test Photographer',
          position: 1
        }
      }
    end

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition)

    medium = ExhibitionMedium.last
    assert_equal 'Test photo', medium.caption
    assert_equal 'Test Photographer', medium.photographer
    assert medium.file.attached?
  end

  test 'should not create exhibition medium without file' do
    assert_no_difference('ExhibitionMedium.count') do
      post admin_exhibition_exhibition_media_url(@exhibition), params: {
        exhibition_medium: {
          caption: 'Test photo',
          photographer: 'Test Photographer'
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Bulk create tests
  test 'should bulk create exhibition media' do
    file1 = fixture_file_upload('test_image.jpg', 'image/jpeg')
    file2 = fixture_file_upload('test_image.jpg', 'image/jpeg')

    assert_difference('ExhibitionMedium.count', 2) do
      post bulk_create_admin_exhibition_exhibition_media_url(@exhibition), params: {
        files: [file1, file2],
        photographer: 'Bulk Photographer'
      }
    end

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition)
    assert_match /Successfully uploaded 2 files/, flash[:notice]
  end

  test 'should handle bulk create with no files' do
    assert_no_difference('ExhibitionMedium.count') do
      post bulk_create_admin_exhibition_exhibition_media_url(@exhibition), params: {
        photographer: 'Test Photographer'
      }
    end

    assert_redirected_to new_admin_exhibition_exhibition_medium_url(@exhibition)
    assert_match /Please select at least one file/, flash[:alert]
  end

  test 'should bulk create with slug' do
    file = fixture_file_upload('test_image.jpg', 'image/jpeg')

    assert_difference('ExhibitionMedium.count', 1) do
      post bulk_create_admin_exhibition_exhibition_media_url(@exhibition.slug), params: {
        files: [file],
        photographer: 'Slug Test'
      }
    end

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition.slug)
  end

  # Edit tests
  test 'should get edit' do
    medium = create_test_medium

    get edit_admin_exhibition_exhibition_medium_url(@exhibition, medium)
    assert_response :success
  end

  # Update tests
  test 'should update exhibition medium' do
    medium = create_test_medium

    patch admin_exhibition_exhibition_medium_url(@exhibition, medium), params: {
      exhibition_medium: {
        caption: 'Updated caption',
        photographer: 'Updated Photographer'
      }
    }

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition)

    medium.reload
    assert_equal 'Updated caption', medium.caption
    assert_equal 'Updated Photographer', medium.photographer
  end

  test 'should update exhibition medium with new file' do
    medium = create_test_medium

    patch admin_exhibition_exhibition_medium_url(@exhibition, medium), params: {
      exhibition_medium: {
        file: fixture_file_upload('test_image.jpg', 'image/jpeg'),
        caption: 'New file uploaded'
      }
    }

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition)

    medium.reload
    assert_equal 'New file uploaded', medium.caption
    assert medium.file.attached?
  end

  # Destroy tests
  test 'should destroy exhibition medium' do
    medium = create_test_medium

    assert_difference('ExhibitionMedium.count', -1) do
      delete admin_exhibition_exhibition_medium_url(@exhibition, medium)
    end

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition)
    assert_equal 'Media deleted successfully', flash[:notice]
  end

  test 'should destroy exhibition medium with slug' do
    medium = create_test_medium

    assert_difference('ExhibitionMedium.count', -1) do
      delete admin_exhibition_exhibition_medium_url(@exhibition.slug, medium)
    end

    assert_redirected_to admin_exhibition_exhibition_media_url(@exhibition.slug)
  end

  test 'should purge attached file when destroying medium' do
    medium = create_test_medium
    blob_id = medium.file.blob.id

    # Use perform_enqueued_jobs to ensure purge_later job runs
    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      delete admin_exhibition_exhibition_medium_url(@exhibition, medium)
    end

    assert_not ExhibitionMedium.exists?(medium.id), "Medium should be destroyed"
  end

  # Storage structure tests
  test 'should generate correct blob key for uploaded file' do
    medium = nil

    assert_difference('ExhibitionMedium.count') do
      post admin_exhibition_exhibition_media_url(@exhibition), params: {
        exhibition_medium: {
          file: fixture_file_upload('test_image.jpg', 'image/jpeg'),
          caption: 'Storage test'
        }
      }
      medium = ExhibitionMedium.last
    end

    expected_prefix = "#{@exhibition.storage_prefix}/media/"
    assert medium.file.blob.key.start_with?(expected_prefix),
           "Blob key should start with #{expected_prefix}, got: #{medium.file.blob.key}"
  end

  private

  def create_test_medium
    medium = @exhibition.exhibition_media.new(
      caption: 'Test caption',
      photographer: 'Test Photographer',
      position: 1
    )

    medium.file.attach(
      io: File.open(@test_image_path),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )

    medium.save!
    medium
  end
end
