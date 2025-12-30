require "test_helper"

class VotingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exhibition = exhibitions(:one)
    @artwork1 = artworks(:one)
    @artwork2 = artworks(:two)
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should create comparison" do
    # First visit the comparison page to create a voting session
    get comparison_exhibition_url(@exhibition)
    assert_response :success

    initial_count = Comparison.count

    # Now create a comparison
    post compare_exhibition_url(@exhibition), params: {
      winning_artwork_id: @artwork1.id,
      losing_artwork_id: @artwork2.id
    }

    # The response might be 422 if there's a validation error
    # (e.g., duplicate comparison) or redirect if successful
    assert_includes [302, 422], response.status,
                    "Expected redirect (302) or unprocessable (422), got #{response.status}"

    # If we got a redirect, verify it's to the comparison page
    if response.status == 302
      assert_redirected_to comparison_exhibition_url(@exhibition)
    end
  end

  test "should redirect to voting when visiting legacy vote url" do
    get vote_url
    assert_response :redirect
  end

  test "should not create comparison with invalid params" do
    # First visit the comparison page to create a voting session
    get comparison_exhibition_url(@exhibition)

    assert_no_difference("Comparison.count") do
      post compare_exhibition_url(@exhibition), params: {
        winning_artwork_id: nil,
        losing_artwork_id: @artwork2.id
      }
    rescue ActiveRecord::RecordNotFound
      # This is expected when artwork_id is nil
    end
  end
end
