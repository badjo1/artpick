class MigrateJvdeData < ActiveRecord::Migration[8.1]
  # Define temporary models for migration
  class Space < ActiveRecord::Base
  end

  class Artist < ActiveRecord::Base
  end

  class Exhibition < ActiveRecord::Base
    belongs_to :space
  end

  class Screen < ActiveRecord::Base
    belongs_to :space
    belongs_to :exhibition, optional: true
  end

  def up
    # 1. Create Crypto Art Museum space
    space = Space.create!(
      name: "Crypto Art Museum",
      description: "A museum dedicated to crypto art exhibitions",
      website_url: "https://caf-expo.vercel.app",
      location: "MINA Gallery"
    )

    # 2. Create JVDE Exhibition (Exhibition #3 - current)
    exhibition = Exhibition.create!(
      space_id: space.id,
      title: "JVDE Exhibition",
      description: "Exhibition #3 - The current ArtPick collection featuring 52 artworks",
      start_date: Date.new(2024, 12, 1),
      end_date: Date.new(2025, 1, 8),
      status: 'active',
      slug: 'jvde-2025',
      luma_url: 'https://luma.com/1zfep8x0',
      manifold_url: 'https://manifold.xyz/@crypto-art-museum/id/4133284080'
    )

    # 3. Create placeholder artist for existing artworks
    unknown_artist = Artist.create!(
      name: "Unknown Artist",
      bio: "Placeholder for artworks without assigned artist"
    )

    # 4. Update all existing artworks to belong to JVDE exhibition and unknown artist
    execute "UPDATE artworks SET exhibition_id = #{exhibition.id}, artist_id = #{unknown_artist.id}"

    # 5. Update all comparisons to belong to JVDE exhibition
    execute "UPDATE comparisons SET exhibition_id = #{exhibition.id}"

    # 6. Update all preferences to belong to JVDE exhibition
    execute "UPDATE preferences SET exhibition_id = #{exhibition.id}"

    # 7. Set all existing users to admin role (already done by default in ExtendUsersWithRoles migration)
    # Users already have role = 'artfriend' as default, admins need to be set manually

    # 8. Create 9 screens for MINA Gallery
    9.times do |i|
      Screen.create!(
        space_id: space.id,
        exhibition_id: exhibition.id,
        name: "Screen #{i + 1}",
        screen_number: (i + 1).to_s,
        location_description: "MINA Gallery",
        active: true
      )
    end

    # 9. Update exhibition counts
    artwork_count = execute("SELECT COUNT(*) FROM artworks WHERE exhibition_id = #{exhibition.id}").first['count']
    comparison_count = execute("SELECT COUNT(*) FROM comparisons WHERE exhibition_id = #{exhibition.id}").first['count']

    execute "UPDATE exhibitions SET artwork_count = #{artwork_count}, comparison_count = #{comparison_count} WHERE id = #{exhibition.id}"
  end

  def down
    # This migration cannot be safely reversed
    raise ActiveRecord::IrreversibleMigration
  end
end
