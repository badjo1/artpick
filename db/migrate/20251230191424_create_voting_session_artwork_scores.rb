class CreateVotingSessionArtworkScores < ActiveRecord::Migration[8.1]
  def change
    create_table :voting_session_artwork_scores do |t|
      t.references :voting_session, null: false, foreign_key: true
      t.references :artwork, null: false, foreign_key: true
      t.references :exhibition, null: false, foreign_key: true
      t.decimal :personal_elo_score, precision: 10, scale: 2, default: 1500.0, null: false
      t.integer :vote_count, default: 0, null: false

      t.timestamps
    end

    add_index :voting_session_artwork_scores, [:voting_session_id, :artwork_id], unique: true, name: 'index_vs_artwork_scores_on_session_and_artwork'
  end
end
