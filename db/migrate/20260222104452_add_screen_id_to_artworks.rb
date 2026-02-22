class AddScreenIdToArtworks < ActiveRecord::Migration[8.1]
  def change
    add_reference :artworks, :screen, foreign_key: true
  end
end
