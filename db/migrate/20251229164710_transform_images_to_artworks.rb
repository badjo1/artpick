class TransformImagesToArtworks < ActiveRecord::Migration[8.1]
  def change
    # Rename table from images to artworks
    rename_table :images, :artworks

    # Add new associations (nullable for now, will be populated by data migration)
    add_reference :artworks, :artist, foreign_key: true
    add_reference :artworks, :exhibition, foreign_key: true

    # Add new metadata fields
    add_column :artworks, :description, :text
    add_column :artworks, :year, :integer
    add_column :artworks, :medium, :string

    # Existing columns are preserved: title, elo_score, vote_count, position, favorite_count
    # Note: exhibition_id will be made NOT NULL after data migration via model validation
  end
end
