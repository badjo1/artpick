class Exhibition < ApplicationRecord
  # Associations
  belongs_to :space
  has_many :artworks, dependent: :restrict_with_error
  has_many :comparisons, dependent: :destroy
  has_many :preferences, dependent: :destroy
  has_many :screens, dependent: :destroy
  has_many :settings, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  has_many :exhibition_media, dependent: :destroy

  # Enums - Convention over Configuration
  # Automatically generates: active?, upcoming?, archived? methods
  # And scopes: Exhibition.active, Exhibition.upcoming, Exhibition.archived
  enum :status, { upcoming: 'upcoming', active: 'active', archived: 'archived' }, prefix: false

  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :number, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }

  # Scopes
  scope :recent, -> { order(start_date: :desc) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }

  def generate_slug
    self.slug = title.parameterize if title.present?
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

  # Calculate minimum comparisons needed before selecting top 5
  # Each comparison shows 2 artworks, so artworks/2 ensures each is seen at least once
  # Uses counter_cache for performance (no COUNT query)
  def minimum_comparisons
    return 1 if artwork_count.zero? # Edge case: prevent division by zero
    (artwork_count / 2.0).ceil
  end

  # Optimal number of comparisons for best quality rankings
  # Seeing each artwork at least once guarantees better informed choices
  # Uses counter_cache for performance (no COUNT query)
  def optimal_comparisons
    artwork_count
  end

  # Storage prefix for Bunny CDN structured storage
  # Format: "03-jvde-2025" (zero-padded number + slug)
  # Used by Artwork and ExhibitionMedium for file paths
  def storage_prefix
    "#{number.to_s.rjust(2, '0')}-#{slug}"
  end
end
