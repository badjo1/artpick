class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.string :title
      t.float :elo_score, default: 1500.0, null: false
      t.integer :vote_count, default: 0, null: false
      t.integer :position

      t.timestamps
    end

    add_index :images, :elo_score
    add_index :images, :position
  end
end
