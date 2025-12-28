class Vote < ApplicationRecord
  # Associations
  belongs_to :winner, class_name: "Image"
  belongs_to :loser, class_name: "Image"
  belongs_to :voting_session, optional: true
  belongs_to :invite_link, optional: true

  # Validations
  validates :winner_id, presence: true
  validates :loser_id, presence: true
  validate :winner_and_loser_must_be_different

  # Callbacks
  after_create :update_elo_scores
  after_create :increment_invite_link_count

  private

  def winner_and_loser_must_be_different
    if winner_id == loser_id
      errors.add(:base, "Winner and loser must be different images")
    end
  end

  def update_elo_scores
    Image.process_vote(winner_id, loser_id)
  end

  def increment_invite_link_count
    invite_link&.increment!(:vote_count)
  end
end
