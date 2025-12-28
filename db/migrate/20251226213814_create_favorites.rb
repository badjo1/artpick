class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :voting_session, null: false, foreign_key: true
      t.references :image, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :favorites, [:voting_session_id, :image_id], unique: true
    add_index :favorites, [:voting_session_id, :position], unique: true
  end
end
