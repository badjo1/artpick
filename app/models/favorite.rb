class Favorite < ApplicationRecord
  belongs_to :voting_session
  belongs_to :image

  validates :position, presence: true, inclusion: { in: 1..5 }
  validates :voting_session_id, uniqueness: { scope: :image_id }
  validates :voting_session_id, uniqueness: { scope: :position }

  after_create :increment_favorite_count
  after_destroy :decrement_favorite_count

  private

  def increment_favorite_count
    image.increment!(:favorite_count)
  end

  def decrement_favorite_count
    image.decrement!(:favorite_count)
  end
end
