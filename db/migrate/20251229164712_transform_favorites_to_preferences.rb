class TransformFavoritesToPreferences < ActiveRecord::Migration[8.1]
  def change
    # Rename table from favorites to preferences
    rename_table :favorites, :preferences

    # Add exhibition context (nullable for now, will be populated by data migration)
    add_reference :preferences, :exhibition, foreign_key: true
    add_reference :preferences, :user, foreign_key: true

    # Rename image_id to artwork_id
    rename_column :preferences, :image_id, :artwork_id

    # Existing columns preserved: voting_session_id, position
  end
end
