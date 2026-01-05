namespace :storage do
  desc "Copy artwork files to new storage locations (physical move in Bunny)"
  task move_artworks: :environment do
    puts "\n🚚 Moving Artwork Files to New Storage Structure"
    puts "=" * 80
    puts "⚠️  WARNING: This will physically copy files in Bunny storage!"
    puts "=" * 80

    print "\nContinue? (yes/no): "
    confirmation = STDIN.gets.chomp.downcase

    unless confirmation == 'yes'
      puts "❌ Migration cancelled"
      exit
    end

    total_count = 0
    success_count = 0
    skip_count = 0
    error_count = 0

    Artwork.includes(:exhibition).find_each do |artwork|
      total_count += 1

      unless artwork.file.attached?
        skip_count += 1
        puts "⏭️  Artwork ##{artwork.id}: No file attached (skipped)"
        next
      end

      old_key = artwork.file.blob.key
      new_key = "#{artwork.exhibition.storage_prefix}/artworks/#{artwork.title.parameterize}#{File.extname(artwork.file.blob.filename.to_s)}"

      # Skip if already at correct location
      if old_key == new_key
        skip_count += 1
        puts "✓  Artwork ##{artwork.id}: Already in correct location"
        next
      end

      print "📦 Artwork ##{artwork.id} (#{artwork.title})... "

      begin
        # Get the Active Storage service
        service = artwork.file.blob.service

        # Download file content from old location
        file_content = artwork.file.blob.download

        # Create a new blob with the new key
        new_blob = ActiveStorage::Blob.create_before_direct_upload!(
          filename: artwork.file.blob.filename,
          byte_size: artwork.file.blob.byte_size,
          checksum: artwork.file.blob.checksum,
          content_type: artwork.file.blob.content_type,
          metadata: artwork.file.blob.metadata
        )

        # Update the new blob's key
        new_blob.update_column(:key, new_key)

        # Upload content to new location
        service.upload(new_key, StringIO.new(file_content))

        # Update the attachment to use the new blob
        artwork.file.attachment.update!(blob: new_blob)

        # Optional: Delete old blob and file
        # Uncomment these lines if you want to delete old files
        # service.delete(old_key) if old_key != new_key
        # old_blob = ActiveStorage::Blob.find_by(key: old_key)
        # old_blob.purge if old_blob

        success_count += 1
        puts "✅"
      rescue => e
        error_count += 1
        puts "❌"
        puts "   Error: #{e.message}"
        Rails.logger.error("Failed to move artwork ##{artwork.id}: #{e.message}")
      end
    end

    puts "\n" + "=" * 80
    puts "Migration Complete!"
    puts "  Total artworks:  #{total_count}"
    puts "  ✅ Moved:        #{success_count}"
    puts "  ⏭️  Skipped:      #{skip_count}"
    puts "  ❌ Errors:       #{error_count}"
    puts "=" * 80

    if error_count > 0
      puts "\n⚠️  Some files failed to move. Check logs for details."
    else
      puts "\n✨ All files successfully moved to new storage structure!"
    end
  end

  desc "Copy media files to new storage locations (physical move in Bunny)"
  task move_media: :environment do
    puts "\n🚚 Moving Media Files to New Storage Structure"
    puts "=" * 80
    puts "⚠️  WARNING: This will physically copy files in Bunny storage!"
    puts "=" * 80

    print "\nContinue? (yes/no): "
    confirmation = STDIN.gets.chomp.downcase

    unless confirmation == 'yes'
      puts "❌ Migration cancelled"
      exit
    end

    total_count = 0
    success_count = 0
    skip_count = 0
    error_count = 0

    ExhibitionMedium.includes(:exhibition).find_each do |medium|
      total_count += 1

      unless medium.file.attached?
        skip_count += 1
        puts "⏭️  Medium ##{medium.id}: No file attached (skipped)"
        next
      end

      old_key = medium.file.blob.key
      new_key = "#{medium.exhibition.storage_prefix}/media/#{medium.file.blob.filename}"

      # Skip if already at correct location
      if old_key == new_key
        skip_count += 1
        puts "✓  Medium ##{medium.id}: Already in correct location"
        next
      end

      print "📦 Medium ##{medium.id}... "

      begin
        # Get the Active Storage service
        service = medium.file.blob.service

        # Download file content from old location
        file_content = medium.file.blob.download

        # Create a new blob with the new key
        new_blob = ActiveStorage::Blob.create_before_direct_upload!(
          filename: medium.file.blob.filename,
          byte_size: medium.file.blob.byte_size,
          checksum: medium.file.blob.checksum,
          content_type: medium.file.blob.content_type,
          metadata: medium.file.blob.metadata
        )

        # Update the new blob's key
        new_blob.update_column(:key, new_key)

        # Upload content to new location
        service.upload(new_key, StringIO.new(file_content))

        # Update the attachment to use the new blob
        medium.file.attachment.update!(blob: new_blob)

        success_count += 1
        puts "✅"
      rescue => e
        error_count += 1
        puts "❌"
        puts "   Error: #{e.message}"
        Rails.logger.error("Failed to move medium ##{medium.id}: #{e.message}")
      end
    end

    puts "\n" + "=" * 80
    puts "Migration Complete!"
    puts "  Total media:     #{total_count}"
    puts "  ✅ Moved:        #{success_count}"
    puts "  ⏭️  Skipped:      #{skip_count}"
    puts "  ❌ Errors:       #{error_count}"
    puts "=" * 80

    if error_count > 0
      puts "\n⚠️  Some files failed to move. Check logs for details."
    else
      puts "\n✨ All files successfully moved to new storage structure!"
    end
  end

  desc "Move all files to new storage structure (artworks and media)"
  task move_all: :environment do
    Rake::Task["storage:move_artworks"].invoke
    puts "\n"
    Rake::Task["storage:move_media"].invoke
  end

  desc "Cleanup orphaned files (DANGEROUS - deletes old files)"
  task cleanup_orphaned: :environment do
    puts "\n🗑️  Cleanup Orphaned Files"
    puts "=" * 80
    puts "⚠️  DANGER: This will DELETE old files from Bunny storage!"
    puts "=" * 80
    puts "\nThis task will:"
    puts "1. Find all blobs that are not attached to any records"
    puts "2. Delete the physical files from Bunny storage"
    puts "3. Delete the blob records from the database"
    puts "\n⚠️  Make sure you've verified the new files work correctly first!"

    print "\nAre you ABSOLUTELY SURE? (type 'DELETE' to confirm): "
    confirmation = STDIN.gets.chomp

    unless confirmation == 'DELETE'
      puts "❌ Cleanup cancelled"
      exit
    end

    # Find orphaned blobs
    orphaned_blobs = ActiveStorage::Blob.left_joins(:attachments)
                                        .where(active_storage_attachments: { id: nil })

    total_count = orphaned_blobs.count
    deleted_count = 0

    puts "\nFound #{total_count} orphaned blobs"

    orphaned_blobs.find_each do |blob|
      print "🗑️  Deleting #{blob.key}... "
      begin
        blob.purge
        deleted_count += 1
        puts "✅"
      rescue => e
        puts "❌"
        puts "   Error: #{e.message}"
      end
    end

    puts "\n" + "=" * 80
    puts "Cleanup Complete!"
    puts "  Total orphaned:  #{total_count}"
    puts "  ✅ Deleted:      #{deleted_count}"
    puts "=" * 80
  end
end
