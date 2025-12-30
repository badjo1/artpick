class VotingSessionArtworkScore < ApplicationRecord
  belongs_to :voting_session
  belongs_to :artwork
  belongs_to :exhibition

  validates :personal_elo_score, presence: true
  validates :vote_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :voting_session_id, uniqueness: { scope: :artwork_id }

  # Find or create a score record for a voting session and artwork
  def self.find_or_initialize_for(voting_session, artwork)
    find_or_initialize_by(
      voting_session: voting_session,
      artwork: artwork,
      exhibition: artwork.exhibition
    )
  end

  # Update Elo score after a comparison
  def self.process_vote(winner_id, loser_id, voting_session)
    winner_artwork = Artwork.find(winner_id)
    loser_artwork = Artwork.find(loser_id)

    winner_score = find_or_initialize_for(voting_session, winner_artwork)
    loser_score = find_or_initialize_for(voting_session, loser_artwork)

    # Ensure scores are persisted with defaults before calculation
    winner_score.save! if winner_score.new_record?
    loser_score.save! if loser_score.new_record?

    # Calculate expected scores
    k_factor = 32
    expected_winner = 1.0 / (1 + 10**((loser_score.personal_elo_score - winner_score.personal_elo_score) / 400.0))
    expected_loser = 1.0 / (1 + 10**((winner_score.personal_elo_score - loser_score.personal_elo_score) / 400.0))

    # Update winner
    winner_score.update_columns(
      personal_elo_score: winner_score.personal_elo_score + k_factor * (1 - expected_winner),
      vote_count: winner_score.vote_count + 1
    )

    # Update loser
    loser_score.update_columns(
      personal_elo_score: loser_score.personal_elo_score + k_factor * (0 - expected_loser),
      vote_count: loser_score.vote_count + 1
    )
  end

  # Get personal ranking for a voting session
  def self.personal_ranking(voting_session, limit = nil)
    where(voting_session: voting_session)
      .order(personal_elo_score: :desc)
      .limit(limit)
      .includes(:artwork)
  end
end
