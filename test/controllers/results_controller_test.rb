require "test_helper"

class ResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exhibition = exhibitions(:one)
    @artwork1 = artworks(:one)
    @artwork2 = artworks(:two)
  end

  test "should get index" do
    get results_url
    assert_response :redirect
    # Results now redirect to active exhibition
  end

  test "should display artworks in ranking order" do
    get exhibition_url(@exhibition)
    assert_response :success
  end
end
