class InviteLink < ApplicationRecord
  # Associations
  has_many :comparisons, dependent: :nullify

  # Validations
  validates :token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_token, on: :create

  # Scopes
  scope :active, -> { where(active: true) }

  # Stats methods
  def comparisons_count
    comparisons.count
  end

  def unique_sessions_count
    # Count unique voting sessions through comparisons
    comparisons.where.not(voting_session_id: nil).distinct.count(:voting_session_id)
  end

  def url
    Rails.application.routes.url_helpers.invite_url(token: token)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
