class ExhibitionMedium < ApplicationRecord
  belongs_to :exhibition
  has_one_attached :file, dependent: :purge_later

  validates :file, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Temporarily disabled - enable after storage migration
  # after_create_commit :set_custom_blob_key_async

  scope :positioned, -> { where.not(position: nil).order(:position) }

  def update_blob_key!
    return false unless file.attached?
    return false unless exhibition.present?

    extension = File.extname(file.blob.filename.to_s)
    filename = file.blob.filename.base

    # Make key unique by including timestamp and random string
    timestamp = Time.current.to_i
    random = SecureRandom.hex(4)
    new_key = "#{exhibition.storage_prefix}/media/#{filename}-#{timestamp}-#{random}#{extension}"

    # Skip if already has correct structure
    return true if file.blob.key.start_with?("#{exhibition.storage_prefix}/media/")

    file.blob.update_column(:key, new_key)
    true
  end

  private

  def set_custom_blob_key_async
    update_blob_key! if file.attached?
  end
end
