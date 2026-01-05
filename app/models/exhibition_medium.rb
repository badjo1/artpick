class ExhibitionMedium < ApplicationRecord
  belongs_to :exhibition
  has_one_attached :file, dependent: :purge_later

  validates :file, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  after_create_commit :set_custom_blob_key_async

  scope :positioned, -> { where.not(position: nil).order(:position) }

  private

  def set_custom_blob_key_async
    UpdateBlobKeyJob.perform_later(self.class.name, id) if file.attached?
  end

  def update_blob_key!
    return false unless file.attached?
    return false unless exhibition.present?

    extension = File.extname(file.blob.filename.to_s)
    filename = file.blob.filename.base
    new_key = "#{exhibition.storage_prefix}/media/#{filename}#{extension}"

    file.blob.update_column(:key, new_key)
    true
  end
end
