class VotingSession < ApplicationRecord
  # Associations
  has_many :comparisons, dependent: :destroy
  has_many :preferences, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  belongs_to :user, optional: true
  belongs_to :invite_link, optional: true

  # Validations
  validates :session_token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_session_token, on: :create

  # Scopes
  scope :active, -> { where("last_activity >= ?", 24.hours.ago) }
  scope :for_user, ->(user) { where(user: user) }

  # Track which pairs have been shown to this session
  def seen_pairs
    comparisons.pluck(:winning_artwork_id, :losing_artwork_id).map(&:sort)
  end

  def has_seen_pair?(artwork1_id, artwork2_id)
    pair = [artwork1_id, artwork2_id].sort
    seen_pairs.include?(pair)
  end

  def touch_activity
    update(last_activity: Time.current)
  end

  def comparisons_count
    comparisons.count
  end

  def preferences_count
    preferences.count
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.hex(32)
  end
end
