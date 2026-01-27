class ExhibitionMedium < ApplicationRecord
  belongs_to :exhibition
  has_one_attached :file, dependent: :purge_later

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp video/mp4].freeze

  validates :file, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :acceptable_file_type

  scope :positioned, -> { where.not(position: nil).order(:position) }

  def self.generate_storage_key(exhibition, filename)
    extension = File.extname(filename).downcase
    base = File.basename(filename, File.extname(filename)).parameterize
    timestamp = Time.current.to_i
    random = SecureRandom.hex(4)
    "#{exhibition.storage_prefix}/media/#{base}-#{timestamp}-#{random}#{extension}"
  end

  def self.create_blob_with_key(exhibition, uploaded_file)
    key = generate_storage_key(exhibition, uploaded_file.original_filename)
    ActiveStorage::Blob.create_and_upload!(
      io: uploaded_file,
      filename: uploaded_file.original_filename,
      content_type: uploaded_file.content_type,
      key: key
    )
  end

  # For rake migration tasks only
  def update_blob_key!
    return false unless file.attached?
    return false unless exhibition.present?

    blob = file.blob
    return true if blob.key.start_with?("#{exhibition.storage_prefix}/media/")

    new_key = self.class.generate_storage_key(exhibition, blob.filename.to_s)

    old_key = blob.key
    service = blob.service

    content = blob.download
    io = content.respond_to?(:read) ? content : StringIO.new(content)
    service.upload(new_key, io)
    blob.update_column(:key, new_key)
    service.delete(old_key)

    true
  end

  private

  def acceptable_file_type
    return unless file.attached?

    unless file.content_type.in?(ALLOWED_CONTENT_TYPES)
      errors.add(:file, "must be a JPEG, PNG, GIF, WebP or MP4 file")
    end
  end
end
