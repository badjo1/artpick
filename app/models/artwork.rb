class Artwork < ApplicationRecord
  # Active Storage attachment for the artwork file
  has_one_attached :file

  # Associations
  belongs_to :exhibition
  belongs_to :artist, optional: true
  has_one :space, through: :exhibition

  has_many :won_comparisons, class_name: "Comparison", foreign_key: "winning_artwork_id", dependent: :destroy
  has_many :lost_comparisons, class_name: "Comparison", foreign_key: "losing_artwork_id", dependent: :destroy
  has_many :preferences, dependent: :destroy
  has_many :check_ins, as: :checkable, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :file, presence: true
  validates :exhibition, presence: true
  validates :elo_score, presence: true, numericality: true
  validates :vote_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes (EXHIBITION-SCOPED!)
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition) }
  scope :ranked, ->(exhibition = nil) {
    scope = exhibition ? where(exhibition: exhibition) : all
    scope.order(elo_score: :desc)
  }
  scope :ranked_by_favorites, ->(exhibition = nil) {
    scope = exhibition ? where(exhibition: exhibition) : all
    scope.order(favorite_count: :desc, elo_score: :desc)
  }
  scope :with_comparisons, -> { where("vote_count > 0") }

  # Callbacks
  after_initialize :set_defaults, if: :new_record?

  # Elo rating algorithm implementation
  # K-factor determines how much ratings change per match
  K_FACTOR = 32

  # Process vote - now exhibition-scoped
  def self.process_vote(winner_id, loser_id, exhibition)
    winner = find(winner_id)
    loser = find(loser_id)

    # Calculate expected scores
    winner_expected = expected_score(winner.elo_score, loser.elo_score)
    loser_expected = expected_score(loser.elo_score, winner.elo_score)

    # Update ratings
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

    # Update positions within exhibition
    update_all_positions(exhibition)
  end

  def self.expected_score(rating_a, rating_b)
    # Elo expected score formula
    # E_A = 1 / (1 + 10^((R_B - R_A) / 400))
    1.0 / (1.0 + (10.0 ** ((rating_b - rating_a) / 400.0)))
  end

  def self.update_all_positions(exhibition)
    # Assign positions based on elo_score ranking within exhibition
    where(exhibition: exhibition).ranked(exhibition).each_with_index do |artwork, index|
      artwork.update_column(:position, index + 1)
    end
  end

  def win_rate
    return 0 if vote_count.zero?
    (won_comparisons.count.to_f / vote_count * 100).round(1)
  end

  private

  def set_defaults
    self.elo_score ||= 1500.0
    self.vote_count ||= 0
    self.favorite_count ||= 0
  end
end
