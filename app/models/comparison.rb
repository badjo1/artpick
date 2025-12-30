class Comparison < ApplicationRecord
  # Associations
  belongs_to :winning_artwork, class_name: "Artwork"
  belongs_to :losing_artwork, class_name: "Artwork"
  belongs_to :exhibition
  belongs_to :user, optional: true
  belongs_to :voting_session, optional: true
  belongs_to :invite_link, optional: true

  # Validations
  validates :winning_artwork_id, presence: true
  validates :losing_artwork_id, presence: true
  validates :exhibition_id, presence: true
  validate :artworks_must_be_different

  # Callbacks
  after_create :update_elo_scores
  after_create :increment_invite_link_count
  after_create :create_check_in

  # Scopes
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition) }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }

  private

  def artworks_must_be_different
    if winning_artwork_id == losing_artwork_id
      errors.add(:base, "Winning and losing artworks must be different")
    end
  end

  def update_elo_scores
    Artwork.process_vote(winning_artwork_id, losing_artwork_id, exhibition)
  end

  def increment_invite_link_count
    invite_link&.increment!(:vote_count)
  end

  def create_check_in
    CheckIn.create!(
      checkable: self,
      user: user,
      voting_session: voting_session,
      exhibition: exhibition,
      action_type: 'vote',
      ip_address: voting_session&.ip_address,
      user_agent: voting_session&.user_agent
    )
  rescue => e
    # Log error but don't fail the comparison
    Rails.logger.error("Failed to create check-in for comparison #{id}: #{e.message}")
  end
end
