class Image < ApplicationRecord
  # Active Storage attachment for the image file
  has_one_attached :file

  # Associations
  has_many :won_votes, class_name: "Vote", foreign_key: "winner_id", dependent: :destroy
  has_many :lost_votes, class_name: "Vote", foreign_key: "loser_id", dependent: :destroy
  has_many :favorites, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :elo_score, presence: true, numericality: true
  validates :vote_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :file, presence: true

  # Scopes
  scope :ranked, -> { order(elo_score: :desc) }
  scope :ranked_by_favorites, -> { order(favorite_count: :desc, elo_score: :desc) }
  scope :with_votes, -> { where("vote_count > 0") }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?

  # Elo rating algorithm implementation
  # K-factor determines how much ratings change per match
  # Higher K = more volatile ratings, lower K = more stable
  K_FACTOR = 32

  def self.process_vote(winner_id, loser_id)
    winner = find(winner_id)
    loser = find(loser_id)

    # Calculate expected scores
    # Expected score is the probability of winning based on current ratings
    winner_expected = expected_score(winner.elo_score, loser.elo_score)
    loser_expected = expected_score(loser.elo_score, winner.elo_score)

    # Update ratings
    # Winner gets 1 point (won), loser gets 0 points (lost)
    # New rating = Old rating + K * (Actual score - Expected score)
    winner.elo_score += K_FACTOR * (1 - winner_expected)
    loser.elo_score += K_FACTOR * (0 - loser_expected)

    # Update vote counts
    winner.vote_count += 1
    loser.vote_count += 1

    # Save both records
    transaction do
      winner.save!
      loser.save!
    end

    # Update positions after rating changes
    update_all_positions
  end

  def self.expected_score(rating_a, rating_b)
    # Elo expected score formula
    # E_A = 1 / (1 + 10^((R_B - R_A) / 400))
    # This calculates the expected probability of A beating B
    1.0 / (1.0 + (10.0 ** ((rating_b - rating_a) / 400.0)))
  end

  def self.update_all_positions
    # Assign positions based on elo_score ranking
    ranked.each_with_index do |image, index|
      image.update_column(:position, index + 1)
    end
  end

  def win_rate
    return 0 if vote_count.zero?
    (won_votes.count.to_f / vote_count * 100).round(1)
  end

  private

  def set_defaults
    self.elo_score ||= 1500.0
    self.vote_count ||= 0
  end
end
