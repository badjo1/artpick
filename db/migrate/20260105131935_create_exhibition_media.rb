class CreateExhibitionMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :exhibition_media do |t|
      t.references :exhibition, null: false, foreign_key: true
      t.text :caption
      t.string :photographer
      t.integer :position

      t.timestamps
    end
  end
end
