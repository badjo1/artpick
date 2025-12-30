class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.text :bio
      t.string :website_url
      t.string :twitter_handle
      t.string :instagram_handle

      t.timestamps
    end

    add_index :artists, :name
  end
end
