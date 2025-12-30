class CreateScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :screens do |t|
      t.references :space, null: false, foreign_key: true
      t.references :exhibition, foreign_key: true
      t.string :name, null: false
      t.string :screen_number
      t.string :location_description
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :screens, [:space_id, :screen_number], unique: true
  end
end
