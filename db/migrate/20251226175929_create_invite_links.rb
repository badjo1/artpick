class CreateInviteLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :invite_links do |t|
      t.string :token, null: false
      t.string :name
      t.integer :vote_count, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :invite_links, :token, unique: true
  end
end
