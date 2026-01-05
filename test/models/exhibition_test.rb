require "test_helper"

class ExhibitionTest < ActiveSupport::TestCase
  setup do
    @space = spaces(:one)
    @exhibition = exhibitions(:one)
  end

  test "should create exhibition" do
    exhibition = Exhibition.new(
      title: "Test Exhibition",
      space: @space,
      status: "upcoming"
    )

    assert exhibition.save
    assert_equal "test-exhibition", exhibition.slug
  end

  test "should generate slug from title" do
    exhibition = Exhibition.create!(
      title: "My New Exhibition",
      space: @space,
      status: "upcoming"
    )

    assert_equal "my-new-exhibition", exhibition.slug
  end

  test "should validate presence of title" do
    exhibition = Exhibition.new(space: @space, status: "upcoming")

    assert_not exhibition.valid?
    assert_includes exhibition.errors[:title], "can't be blank"
  end

  test "should validate uniqueness of slug" do
    Exhibition.create!(title: "Test", slug: "test-slug", space: @space, status: "upcoming")
    duplicate = Exhibition.new(title: "Test 2", slug: "test-slug", space: @space, status: "upcoming")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  # Business Rule: Artwork Protection
  test "should not destroy exhibition with artworks" do
    # Setup: Create exhibition with artworks
    exhibition = Exhibition.create!(
      title: "Exhibition with Artworks",
      space: @space,
      status: "active"
    )

    artwork = exhibition.artworks.new(
      title: "Test Artwork",
      elo_score: 1500,
      vote_count: 0
    )

    artwork.file.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )

    artwork.save!

    # Attempt to destroy exhibition
    result = exhibition.destroy

    # Assert destruction failed
    assert_not result, "Exhibition should not be destroyed when artworks exist"
    assert_not exhibition.destroyed?, "Exhibition should still exist in database"

    # Assert error message is present
    assert exhibition.errors[:base].any?, "Should have base errors"
    assert_includes exhibition.errors.full_messages.join(", "),
                    "Cannot delete record because dependent artworks exist"

    # Verify exhibition and artwork still exist
    assert Exhibition.exists?(exhibition.id), "Exhibition should still exist"
    assert Artwork.exists?(artwork.id), "Artwork should still exist"
  end

  test "should destroy exhibition without artworks" do
    # Setup: Create exhibition without artworks
    exhibition = Exhibition.create!(
      title: "Empty Exhibition",
      space: @space,
      status: "upcoming"
    )

    exhibition_id = exhibition.id

    # Attempt to destroy exhibition
    result = exhibition.destroy

    # Assert destruction succeeded
    assert result, "Exhibition should be destroyed when no artworks exist"
    assert exhibition.destroyed?, "Exhibition should be marked as destroyed"

    # Verify exhibition no longer exists
    assert_not Exhibition.exists?(exhibition_id), "Exhibition should be deleted from database"
  end

  test "should destroy exhibition after manually deleting all artworks" do
    # Setup: Create exhibition with artworks
    exhibition = Exhibition.create!(
      title: "Exhibition to Clean",
      space: @space,
      status: "active"
    )

    artwork = exhibition.artworks.new(
      title: "Test Artwork",
      elo_score: 1500,
      vote_count: 0
    )

    artwork.file.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )

    artwork.save!

    exhibition_id = exhibition.id

    # First attempt should fail
    assert_not exhibition.destroy, "Should fail with artworks"

    # Manually delete artworks
    exhibition.artworks.destroy_all

    # Reload to clear any cached associations
    exhibition.reload

    # Second attempt should succeed
    assert exhibition.destroy, "Should succeed after deleting artworks"
    assert_not Exhibition.exists?(exhibition_id), "Exhibition should be deleted"
  end

  # Enum tests
  test "should have status enum with correct values" do
    exhibition = @exhibition

    # Test predicate methods
    exhibition.update!(status: "active")
    assert exhibition.active?
    assert_not exhibition.upcoming?
    assert_not exhibition.archived?

    exhibition.update!(status: "upcoming")
    assert exhibition.upcoming?
    assert_not exhibition.active?
    assert_not exhibition.archived?

    exhibition.update!(status: "archived")
    assert exhibition.archived?
    assert_not exhibition.active?
    assert_not exhibition.upcoming?
  end

  test "should have status scopes" do
    active_ex = Exhibition.create!(title: "Active", space: @space, status: "active")
    upcoming_ex = Exhibition.create!(title: "Upcoming", space: @space, status: "upcoming")
    archived_ex = Exhibition.create!(title: "Archived", space: @space, status: "archived")

    assert_includes Exhibition.active, active_ex
    assert_not_includes Exhibition.active, upcoming_ex

    assert_includes Exhibition.upcoming, upcoming_ex
    assert_not_includes Exhibition.upcoming, active_ex

    assert_includes Exhibition.archived, archived_ex
    assert_not_includes Exhibition.archived, active_ex
  end

  # Counter cache tests
  test "should use counter cache for artwork_count" do
    exhibition = Exhibition.create!(
      title: "Counter Cache Test",
      space: @space,
      status: "active"
    )

    # Initial count should be 0
    assert_equal 0, exhibition.artwork_count

    # Create artwork
    artwork = exhibition.artworks.new(
      title: "Test Artwork",
      elo_score: 1500,
      vote_count: 0
    )

    artwork.file.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )

    artwork.save!

    # Counter should increment
    exhibition.reload
    assert_equal 1, exhibition.artwork_count

    # Create another artwork
    artwork2 = exhibition.artworks.new(
      title: "Test Artwork 2",
      elo_score: 1500,
      vote_count: 0
    )

    artwork2.file.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'test_image.jpg')),
      filename: 'test_image.jpg',
      content_type: 'image/jpeg'
    )

    artwork2.save!

    # Counter should increment again
    exhibition.reload
    assert_equal 2, exhibition.artwork_count

    # Delete artwork
    artwork.destroy

    # Counter should decrement
    exhibition.reload
    assert_equal 1, exhibition.artwork_count
  end

  test "minimum_comparisons should return artwork_count divided by 2" do
    exhibition = Exhibition.create!(
      title: "Min Comparisons Test",
      space: @space,
      status: "active",
      artwork_count: 52
    )

    assert_equal 26, exhibition.minimum_comparisons
  end

  test "minimum_comparisons should handle odd numbers" do
    exhibition = Exhibition.create!(
      title: "Odd Test",
      space: @space,
      status: "active",
      artwork_count: 51
    )

    assert_equal 26, exhibition.minimum_comparisons
  end

  test "minimum_comparisons should handle zero artworks" do
    exhibition = Exhibition.create!(
      title: "Empty Test",
      space: @space,
      status: "active",
      artwork_count: 0
    )

    assert_equal 1, exhibition.minimum_comparisons
  end

  test "optimal_comparisons should return artwork_count" do
    exhibition = Exhibition.create!(
      title: "Optimal Test",
      space: @space,
      status: "active",
      artwork_count: 52
    )

    assert_equal 52, exhibition.optimal_comparisons
  end
end
