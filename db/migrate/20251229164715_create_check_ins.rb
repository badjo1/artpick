class CreateCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_table :check_ins do |t|
      t.references :checkable, polymorphic: true, null: false
      t.references :user, foreign_key: true
      t.references :voting_session, foreign_key: true
      t.references :exhibition, foreign_key: true
      t.references :screen, foreign_key: true
      t.string :action_type, null: false
      t.string :ip_address
      t.string :user_agent
      t.jsonb :metadata

      t.timestamps
    end

    add_index :check_ins, [:checkable_type, :checkable_id]
    add_index :check_ins, :action_type
    add_index :check_ins, :created_at
  end
end
