class CreateExhibitions < ActiveRecord::Migration[8.1]
  def change
    create_table :exhibitions do |t|
      t.references :space, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :status, default: 'upcoming', null: false
      t.string :slug, null: false
      t.string :luma_url
      t.string :manifold_url
      t.string :poap_url
      t.integer :artwork_count, default: 0
      t.integer :comparison_count, default: 0

      t.timestamps
    end

    add_index :exhibitions, :slug, unique: true
    add_index :exhibitions, :status
  end
end
