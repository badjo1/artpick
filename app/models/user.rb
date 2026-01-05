class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :sessions, dependent: :destroy
  has_many :comparisons, dependent: :destroy
  has_many :preferences, dependent: :destroy
  has_many :check_ins, dependent: :destroy

  # Validations
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Constants
  ROLES = %w[admin artist artfriend].freeze

  validates :role, inclusion: { in: ROLES }

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :artists, -> { where(role: 'artist') }
  scope :artfriends, -> { where(role: 'artfriend') }

  # Role methods
  def admin?
    role == 'admin'
  end

  def artist?
    role == 'artist'
  end

  def artfriend?
    role == 'artfriend'
  end
end
