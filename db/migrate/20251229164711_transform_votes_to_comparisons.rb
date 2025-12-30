class TransformVotesToComparisons < ActiveRecord::Migration[8.1]
  def change
    # Rename table from votes to comparisons
    rename_table :votes, :comparisons

    # Add exhibition context (nullable for now, will be populated by data migration)
    add_reference :comparisons, :exhibition, foreign_key: true
    add_reference :comparisons, :user, foreign_key: true

    # Rename columns to be more descriptive
    rename_column :comparisons, :winner_id, :winning_artwork_id
    rename_column :comparisons, :loser_id, :losing_artwork_id

    # Existing columns preserved: voting_session_id, invite_link_id
  end
end
