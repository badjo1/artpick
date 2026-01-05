namespace :storage do
  desc "Verify all artwork blob keys match expected structure"
  task verify_artwork_keys: :environment do
    puts "\nVerifying Artwork Blob Keys"
    puts "=" * 80

    correct_count = 0
    incorrect_count = 0

    Artwork.includes(:exhibition).find_each do |artwork|
      next unless artwork.file.attached?

      expected_key = "#{artwork.exhibition.storage_prefix}/artworks/#{artwork.title.parameterize}#{File.extname(artwork.file.blob.filename.to_s)}"
      actual_key = artwork.file.blob.key

      if expected_key == actual_key
        correct_count += 1
      else
        incorrect_count += 1
        puts "❌ Artwork ##{artwork.id}: #{artwork.title}"
        puts "   Expected: #{expected_key}"
        puts "   Actual:   #{actual_key}"
      end
    end

    puts "=" * 80
    puts "Verification Results:"
    puts "  ✅ Correct:   #{correct_count}"
    puts "  ❌ Incorrect: #{incorrect_count}"
    puts "=" * 80

    if incorrect_count.zero?
      puts "✨ All blob keys are correctly structured!"
    else
      puts "\n💡 Run 'rails storage:migrate_artwork_keys' to fix incorrect keys"
    end
  end

  desc "Show current blob keys for all artworks"
  task show_artwork_keys: :environment do
    puts "\nCurrent Artwork Blob Keys"
    puts "=" * 80

    Artwork.includes(:exhibition).find_each do |artwork|
      next unless artwork.file.attached?

      puts "Artwork ##{artwork.id}: #{artwork.title}"
      puts "  Exhibition: #{artwork.exhibition.storage_prefix}"
      puts "  Current key: #{artwork.file.blob.key}"
      puts "  Expected key: #{artwork.exhibition.storage_prefix}/artworks/#{artwork.title.parameterize}#{File.extname(artwork.file.blob.filename.to_s)}"
      puts "-" * 80
    end
  end

  desc "Migrate all artwork blob keys to new structure"
  task migrate_artwork_keys: :environment do
    puts "\nStarting blob key migration..."
    puts "=" * 80

    total_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0

    Artwork.includes(:exhibition).find_each do |artwork|
      total_count += 1

      unless artwork.file.attached?
        skipped_count += 1
        puts "⚠️  Artwork ##{artwork.id}: No file attached (skipped)"
        next
      end

      print "Processing artwork #{total_count}... "

      if artwork.update_blob_key!
        updated_count += 1
        puts "✅"
      else
        error_count += 1
        puts "❌"
      end
    end

    puts "=" * 80
    puts "Migration complete!"
    puts "  Total artworks: #{total_count}"
    puts "  Updated:        #{updated_count}"
    puts "  Skipped:        #{skipped_count} (no file attached)"
    puts "  Errors:         #{error_count}"
    puts "=" * 80

    if error_count > 0
      puts "\n⚠️  Some artworks failed to update. Check logs for details."
    else
      puts "\n✨ All artworks successfully migrated!"
    end
  end

  desc "Migrate exhibition media blob keys to new structure"
  task migrate_media_keys: :environment do
    puts "\nStarting media blob key migration..."
    puts "=" * 80

    total_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0

    ExhibitionMedium.includes(:exhibition).find_each do |medium|
      total_count += 1

      unless medium.file.attached?
        skipped_count += 1
        puts "⚠️  Medium ##{medium.id}: No file attached (skipped)"
        next
      end

      print "Processing medium #{total_count}... "

      if medium.update_blob_key!
        updated_count += 1
        puts "✅"
      else
        error_count += 1
        puts "❌"
      end
    end

    puts "=" * 80
    puts "Migration complete!"
    puts "  Total media: #{total_count}"
    puts "  Updated:     #{updated_count}"
    puts "  Skipped:     #{skipped_count} (no file attached)"
    puts "  Errors:      #{error_count}"
    puts "=" * 80

    if error_count > 0
      puts "\n⚠️  Some media failed to update. Check logs for details."
    else
      puts "\n✨ All media successfully migrated!"
    end
  end

  desc "Migrate all blob keys (artworks and media)"
  task migrate_all: :environment do
    Rake::Task["storage:migrate_artwork_keys"].invoke
    puts "\n"
    Rake::Task["storage:migrate_media_keys"].invoke
  end

  desc "Generate summary of storage structure"
  task summary: :environment do
    puts "\nStorage Structure Summary"
    puts "=" * 80

    Exhibition.includes(:artworks, :exhibition_media).order(:number).each do |exhibition|
      puts "\n#{exhibition.storage_prefix}/"

      if exhibition.artworks.any?
        puts "├── artworks/ (#{exhibition.artworks.count} files)"
        exhibition.artworks.limit(3).each do |artwork|
          next unless artwork.file.attached?
          filename = "#{artwork.title.parameterize}#{File.extname(artwork.file.blob.filename.to_s)}"
          puts "│   ├── #{filename}"
        end
        puts "│   └── ..." if exhibition.artworks.count > 3
      end

      if exhibition.exhibition_media.any?
        puts "└── media/ (#{exhibition.exhibition_media.count} files)"
        exhibition.exhibition_media.limit(3).each do |medium|
          next unless medium.file.attached?
          puts "    ├── #{medium.file.blob.filename}"
        end
        puts "    └── ..." if exhibition.exhibition_media.count > 3
      end
    end

    puts "\n" + "=" * 80
  end
end
