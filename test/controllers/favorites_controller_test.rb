require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exhibition = exhibitions(:one)
  end

  test "should redirect to comparison when not enough comparisons made" do
    # First create a voting session
    get comparison_exhibition_url(@exhibition)

    # Try to access preferences without enough comparisons
    get preferences_exhibition_url(@exhibition)
    # Should redirect back to comparison page
    assert_response :redirect
    assert_redirected_to comparison_exhibition_url(@exhibition)
  end

  test "should create preference" do
    # First create a voting session
    get comparison_exhibition_url(@exhibition)

    post preferences_exhibition_url(@exhibition), params: {
      artwork_ids: [artworks(:one).id, artworks(:two).id]
    }
    assert_response :redirect
  end
end
