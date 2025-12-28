require "test_helper"

class ResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @image1 = Image.create!(title: "Test Image 1", elo_score: 1600)
    @image2 = Image.create!(title: "Test Image 2", elo_score: 1500)
  end

  test "should get index" do
    get results_url
    assert_response :success
  end

  test "should display images in ranking order" do
    get results_url
    assert_response :success
    assert_select "h1", "Resultaten"
  end
end
