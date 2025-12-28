class AddFavoriteCountToImages < ActiveRecord::Migration[8.1]
  def change
    add_column :images, :favorite_count, :integer, default: 0, null: false
  end
end
