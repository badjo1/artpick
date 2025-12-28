class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.bigint :winner_id, null: false
      t.bigint :loser_id, null: false
      t.bigint :voting_session_id
      t.bigint :invite_link_id

      t.timestamps
    end

    add_index :votes, :winner_id
    add_index :votes, :loser_id
    add_index :votes, :voting_session_id
    add_index :votes, :invite_link_id
  end
end
