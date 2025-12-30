class Space < ApplicationRecord
  # Associations
  has_many :exhibitions, dependent: :destroy
  has_many :screens, dependent: :destroy
  has_many :artworks, through: :exhibitions

  # Validations
  validates :name, presence: true

  # Scopes
  scope :with_active_exhibitions, -> { joins(:exhibitions).merge(Exhibition.active).distinct }
end
