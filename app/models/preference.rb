class Preference < ApplicationRecord
  # Associations
  belongs_to :artwork
  belongs_to :exhibition
  belongs_to :user, optional: true
  belongs_to :voting_session, optional: true

  # Validations
  validates :artwork_id, presence: true
  validates :exhibition_id, presence: true
  validates :position, presence: true, inclusion: { in: 1..5 }
  validates :artwork_id, uniqueness: { scope: [:voting_session_id, :user_id] }
  validates :position, uniqueness: { scope: [:voting_session_id, :user_id] }

  # Scopes
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition) }
  scope :for_session, ->(session) { where(voting_session: session) }
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(position: :asc) }
  scope :top_artworks, -> {
    group(:artwork_id).count.sort_by { |_, count| -count }.to_h
  }

  # Callbacks
  after_create :increment_artwork_favorite_count
  after_destroy :decrement_artwork_favorite_count

  private

  def increment_artwork_favorite_count
    artwork.increment!(:favorite_count)
  end

  def decrement_artwork_favorite_count
    artwork.decrement!(:favorite_count)
  end
end
