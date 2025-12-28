require "test_helper"

class VotingControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create test images
    @image1 = Image.create!(title: "Test Image 1")
    @image2 = Image.create!(title: "Test Image 2")
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should create vote" do
    assert_difference("Vote.count") do
      post vote_url, params: { winner_id: @image1.id, loser_id: @image2.id }
    end

    assert_redirected_to vote_url
  end

  test "should redirect to results when voting closed" do
    # Set deadline to past
    Setting.set_value("voting_deadline", 1.day.ago.to_s)

    get vote_url
    assert_redirected_to results_url
  end

  test "should not create vote with invalid params" do
    assert_no_difference("Vote.count") do
      post vote_url, params: { winner_id: nil, loser_id: @image2.id }
    end
  end
end
