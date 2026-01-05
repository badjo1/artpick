require 'test_helper'

class Admin::ExhibitionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update(role: 'admin')
    sign_in_as @user

    @exhibition = exhibitions(:one)
    @space = spaces(:one)
  end

  test 'should get index' do
    get admin_exhibitions_url
    assert_response :success
  end

  test 'should get new' do
    get new_admin_exhibition_url
    assert_response :success
  end

  test 'should create exhibition' do
    assert_difference('Exhibition.count') do
      post admin_exhibitions_url, params: {
        exhibition: {
          title: 'New Exhibition',
          description: 'Test description',
          space_id: @space.id,
          start_date: Date.today,
          end_date: Date.today + 30.days,
          status: 'upcoming',
          slug: 'new-exhibition'
        }
      }
    end

    assert_redirected_to admin_exhibitions_url
  end

  test 'should get edit' do
    get edit_admin_exhibition_url(@exhibition)
    assert_response :success
  end

  test 'should update exhibition title' do
    patch admin_exhibition_url(@exhibition), params: {
      exhibition: {
        title: 'Updated Title'
      }
    }

    assert_redirected_to admin_exhibitions_url
    @exhibition.reload
    assert_equal 'Updated Title', @exhibition.title
  end

  test 'should update exhibition dates' do
    new_start_date = Date.new(2025, 6, 1)
    new_end_date = Date.new(2025, 7, 1)

    patch admin_exhibition_url(@exhibition), params: {
      exhibition: {
        start_date: new_start_date,
        end_date: new_end_date
      }
    }

    assert_redirected_to admin_exhibitions_url
    @exhibition.reload
    assert_equal new_start_date, @exhibition.start_date
    assert_equal new_end_date, @exhibition.end_date
  end

  test 'should update exhibition status' do
    patch admin_exhibition_url(@exhibition), params: {
      exhibition: {
        status: 'archived'
      }
    }

    assert_redirected_to admin_exhibitions_url
    @exhibition.reload
    assert_equal 'archived', @exhibition.status
  end

  test 'should not destroy exhibition with artworks' do
    # Ensure exhibition has artworks
    if @exhibition.artworks.empty?
      artwork = @exhibition.artworks.new(title: "Test Artwork", elo_score: 1500, vote_count: 0)
      artwork.file.attach(
        io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpeg'
      )
      artwork.save!
    end

    assert_no_difference('Exhibition.count') do
      delete admin_exhibition_url(@exhibition)
    end

    assert_redirected_to admin_exhibitions_url
    assert_match /Cannot delete exhibition/, flash[:alert]
  end

  test 'should destroy exhibition without artworks' do
    # Create exhibition without artworks
    exhibition = Exhibition.create!(
      title: "Empty Exhibition",
      space: @space,
      status: "upcoming"
    )

    assert_difference('Exhibition.count', -1) do
      delete admin_exhibition_url(exhibition)
    end

    assert_redirected_to admin_exhibitions_url
    assert_equal 'Exhibition deleted successfully', flash[:notice]
  end
end
