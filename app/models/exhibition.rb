class Exhibition < ApplicationRecord
  # Associations
  belongs_to :space
  has_many :artworks, dependent: :destroy
  has_many :comparisons, dependent: :destroy
  has_many :preferences, dependent: :destroy
  has_many :screens
  has_many :settings, dependent: :destroy
  has_many :check_ins

  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[upcoming active archived] }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :archived, -> { where(status: 'archived') }
  scope :upcoming, -> { where(status: 'upcoming') }
  scope :recent, -> { order(start_date: :desc) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }

  def generate_slug
    self.slug = title.parameterize
  end

  # Use slug for URLs instead of id
  def to_param
    slug
  end

  def voting_open?
    active? && (end_date.nil? || end_date >= Date.today)
  end

  def top_artworks(limit = 10)
    artworks.ranked(self).limit(limit)
  end

  def active?
    status == 'active'
  end

  def upcoming?
    status == 'upcoming'
  end

  def archived?
    status == 'archived'
  end

  # Calculate minimum comparisons needed before selecting top 5
  # Each comparison shows 2 artworks, so artworks/2 ensures each is seen at least once
  def minimum_comparisons
    (artworks.count / 2.0).ceil
  end

  # Optimal number of comparisons for best quality rankings
  # Seeing each artwork at least once guarantees better informed choices
  def optimal_comparisons
    artworks.count
  end
end
