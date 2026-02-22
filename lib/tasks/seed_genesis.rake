namespace :db do
  desc "Seed the Genesis exhibition and renumber existing exhibitions"
  task seed_genesis: :environment do
    puts "==> Renumbering exhibitions..."

    # Step 1: Renumber JVDE from 1 -> 3
    jvde = Exhibition.find_by(slug: "jvde-2025")
    if jvde && jvde.number != 3
      old_prefix = jvde.storage_prefix
      jvde.update_column(:number, 3)
      new_prefix = jvde.storage_prefix
      puts "  JVDE: number #{old_prefix} -> #{new_prefix}"

      # Move files on Bunny CDN from 01-jvde-2025/ to 03-jvde-2025/
      browser = BunnyBrowser.new
      begin
        artworks = browser.list("#{old_prefix}/artworks")
        artworks.each do |entry|
          next if entry["IsDirectory"] || entry["ObjectName"] == ".folder"
          filename = entry["ObjectName"]
          puts "  Moving #{old_prefix}/artworks/#{filename} -> #{new_prefix}/artworks/#{filename}"

          # Download and re-upload to new path
          cdn_url = browser.cdn_url("#{old_prefix}/artworks/#{filename}")
          data = Net::HTTP.get(URI(cdn_url))
          browser.upload("#{new_prefix}/artworks", filename, StringIO.new(data), "image/jpeg")
          browser.delete("#{old_prefix}/artworks/#{filename}")
        end
      rescue => e
        puts "  Warning: Could not move Bunny files: #{e.message}"
      end

      # Update Active Storage blob keys
      jvde.artworks.each do |artwork|
        next unless artwork.file.attached?
        blob = artwork.file.blob
        if blob.key.start_with?("#{old_prefix}/")
          new_key = blob.key.sub(old_prefix, new_prefix)
          blob.update_column(:key, new_key)
          puts "  Blob key: #{blob.key}"
        end
      end

      jvde.exhibition_media.each do |medium|
        next unless medium.file.attached?
        blob = medium.file.blob
        if blob.key.start_with?("#{old_prefix}/")
          new_key = blob.key.sub(old_prefix, new_prefix)
          blob.update_column(:key, new_key)
          puts "  Blob key: #{blob.key}"
        end
      end
    else
      puts "  JVDE: already number 3 (or not found)"
    end

    puts ""
    puts "==> Seeding Genesis exhibition..."

    # Space (reuse existing MINA Gallery)
    space = Space.find_or_create_by!(name: "Crypto Art Museum - MINA Gallery") do |s|
      s.description = "Contemporary art & coffee space within Hotel Fritz, Amsterdam. Home of the Popup Crypto Art Museum."
      s.location = "Hotel Fritz, Amsterdam"
      s.website_url = "https://www.galeriemina.nl"
    end
    puts "  Space: #{space.name} (##{space.id})"

    # Artists
    artists = {}

    artists[:handiedan] = Artist.find_or_create_by!(name: "Handiedan") do |a|
      a.bio = "Dutch artist known for intricate collage work blending vintage imagery with geometric patterns and symmetry."
    end

    artists[:rik] = Artist.find_or_create_by!(name: "Rik Oostenbroek") do |a|
      a.bio = "Dutch digital artist creating fluid, abstract compositions that explore color, form and movement."
      a.instagram_handle = "rikoostenbroek"
    end

    artists[:rutger] = Artist.find_or_create_by!(name: "Rutger van der Tas") do |a|
      a.bio = "Dutch digital artist and creative director exploring distortion, identity and the boundaries of portraiture."
      a.instagram_handle = "rutgervandertas"
    end

    artists.each { |_, a| puts "  Artist: #{a.name} (##{a.id})" }

    # Exhibition
    exhibition = Exhibition.find_or_create_by!(slug: "genesis") do |e|
      e.title = "Genesis"
      e.number = 1
      e.space = space
      e.description = "The opening exhibition of the Popup Crypto Art Museum at Galerij Mina within Hotel Fritz, Amsterdam. " \
        "Featuring works by Handiedan, Rik Oostenbroek and Rutger van der Tas across two floors. " \
        "Digital artworks displayed on OP_enspace screens with conceptual design by The Playground Amsterdam. " \
        "An experiment in shared creation, supporting a permanent collection in the Copernicus Sphere."
      e.start_date = Date.new(2025, 8, 29)
      e.end_date = Date.new(2025, 9, 28)
      e.status = "archived"
      e.luma_url = "https://luma.com/rr76lug0"
    end
    puts "  Exhibition: #{exhibition.title} (##{exhibition.id}, number=#{exhibition.number}, prefix=#{exhibition.storage_prefix})"

    # Exhibition Media — files already exist on Bunny at 01-genesis/media/
    # Since storage_prefix is 01-genesis, we register them as Active Storage blobs
    # pointing to the existing keys
    media_files = [
      "Expo 1.jpg", "Expo 2.jpg", "Expo 3.jpg", "Expo 4.jpg", "Expo 5.jpg",
      "Expo 6.jpg", "Expo 7.jpg", "Expo 8.jpg", "Expo 10.jpg", "Expo 11.jpg",
      "Expo 12.jpg", "Expo 13.jpg", "Expo 14.jpg", "Expo 15.jpg", "Expo 16.jpg",
      "Expo 17.jpg", "Expo 18.jpg", "Expo 19.jpg", "Foto 20.jpg", "Expo 21.jpg",
      "Expo 22.jpg", "Expo 23.jpg"
    ]

    browser = BunnyBrowser.new

    media_files.each_with_index do |filename, i|
      existing = exhibition.exhibition_media.joins(:file_blob).where(active_storage_blobs: { filename: filename }).first
      if existing
        puts "  Media: #{filename} (already exists, skipping)"
        next
      end

      source_key = "01-genesis/media/#{filename}"
      cdn_url = browser.cdn_url(source_key)
      puts "  Media: downloading #{filename}..."

      response = Net::HTTP.get_response(URI(URI::DEFAULT_PARSER.escape(cdn_url)))
      unless response.is_a?(Net::HTTPSuccess)
        puts "  Media: FAILED #{filename} (#{response.code})"
        next
      end

      storage_key = "#{exhibition.storage_prefix}/media/#{filename.parameterize(separator: '-')}.jpg"
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(response.body),
        filename: filename,
        content_type: "image/jpeg",
        key: storage_key
      )
      medium = exhibition.exhibition_media.create!(file: blob, position: i + 1)
      puts "  Media: #{filename} -> #{storage_key} (##{medium.id})"
    end

    # Video
    video_filename = "genesis.mp4"
    existing_video = exhibition.exhibition_media.joins(:file_blob).where(active_storage_blobs: { filename: video_filename }).first
    unless existing_video
      source_key = "01-genesis/media/#{video_filename}"
      cdn_url = browser.cdn_url(source_key)
      puts "  Media: downloading #{video_filename}..."

      response = Net::HTTP.get_response(URI(URI::DEFAULT_PARSER.escape(cdn_url)))
      if response.is_a?(Net::HTTPSuccess)
        storage_key = "#{exhibition.storage_prefix}/media/genesis.mp4"
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(response.body),
          filename: video_filename,
          content_type: "video/mp4",
          key: storage_key
        )
        medium = exhibition.exhibition_media.create!(file: blob, position: media_files.length + 1)
        puts "  Media: #{video_filename} -> #{storage_key} (##{medium.id})"
      else
        puts "  Media: FAILED #{video_filename} (#{response.code})"
      end
    else
      puts "  Media: #{video_filename} (already exists, skipping)"
    end

    puts ""
    puts "==> Done!"
    puts "  Exhibition: #{exhibition.title} (##{exhibition.id}, prefix=#{exhibition.storage_prefix})"
    puts "  Artists: #{artists.values.map(&:name).join(', ')}"
    puts "  Media: #{exhibition.exhibition_media.count} files"
    puts ""
    puts "  Exhibition numbers: #{Exhibition.order(:number).map { |e| "#{e.number}=#{e.slug}" }.join(', ')}"
    puts ""
    puts "NOTE: Artworks need to be added separately once artwork files"
    puts "are uploaded to #{exhibition.storage_prefix}/artworks/ on Bunny CDN."
  end
end
