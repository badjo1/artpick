# Custom storage key generation for organized file structure
# Files stored as: {exhibition-slug}/{artwork-slug}.{ext}
# Example: jvde-2025/portrait-of-a-woman.jpg

module CustomStorageKey
  extend ActiveSupport::Concern

  included do
    # Generate custom key before creating blob
    before_create :set_custom_storage_key, if: -> { file.attached? && file.blob.new_record? }
  end

  private

  def set_custom_storage_key
    return unless file.attached? && exhibition.present?

    blob = file.blob
    return unless blob.new_record?

    # Generate custom key: exhibition-slug/artwork-title.ext
    exhibition_slug = exhibition.slug
    artwork_slug = title.parameterize
    extension = File.extname(blob.filename.to_s)

    # Custom key format
    custom_key = "#{exhibition_slug}/#{artwork_slug}#{extension}"

    # Override the default random key
    blob.key = custom_key
  end

  # Alternative: Set custom key when attaching file
  def attach_file_with_custom_key(file_io, filename:, content_type:)
    exhibition_slug = exhibition.slug
    artwork_slug = title.parameterize
    extension = File.extname(filename)

    custom_filename = "#{exhibition_slug}/#{artwork_slug}#{extension}"

    file.attach(
      io: file_io,
      filename: custom_filename,
      content_type: content_type,
      key: custom_filename # This sets the storage key
    )
  end
end
