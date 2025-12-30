class Artist < ApplicationRecord
  # Associations
  has_many :artworks
  has_many :exhibitions, through: :artworks

  # Validations
  validates :name, presence: true

  # Scopes
  scope :with_artworks, -> { joins(:artworks).distinct }
  scope :ordered_by_name, -> { order(:name) }
end
