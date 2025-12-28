class InviteLink < ApplicationRecord
  # Associations
  has_many :votes, dependent: :nullify

  # Validations
  validates :token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_token, on: :create

  # Scopes
  scope :active, -> { where(active: true) }

  def url
    Rails.application.routes.url_helpers.invite_url(token: token)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
