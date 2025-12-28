class CreateVotingSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :voting_sessions do |t|
      t.string :session_token, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_activity

      t.timestamps
    end

    add_index :voting_sessions, :session_token, unique: true
  end
end
