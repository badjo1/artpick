class VotingSession < ApplicationRecord
  # Associations
  has_many :votes, dependent: :destroy
  has_many :favorites, dependent: :destroy

  # Validations
  validates :session_token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_session_token, on: :create

  # Track which pairs have been shown to this session
  def seen_pairs
    votes.pluck(:winner_id, :loser_id).map(&:sort)
  end

  def has_seen_pair?(image1_id, image2_id)
    pair = [image1_id, image2_id].sort
    seen_pairs.include?(pair)
  end

  def touch_activity
    update(last_activity: Time.current)
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.hex(32)
  end
end
