class Screen < ApplicationRecord
  # Associations
  belongs_to :space
  belongs_to :exhibition, optional: true
  has_many :check_ins, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :screen_number, uniqueness: { scope: :space_id }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_space, ->(space) { where(space: space) }
  scope :for_exhibition, ->(exhibition) { where(exhibition: exhibition) }
end
