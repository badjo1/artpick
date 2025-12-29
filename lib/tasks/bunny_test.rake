namespace :bunny do
  desc "Test Bunny.net storage connection and upload"
  task test: :environment do
    puts "🧪 Testing Bunny.net Storage Connection..."
    puts ""

    # Check environment variables
    puts "1️⃣ Checking environment variables:"
    storage_zone = ENV['BUNNY_STORAGE_ZONE']
    access_key = ENV['BUNNY_ACCESS_KEY']
    secret_key = ENV['BUNNY_SECRET_KEY']
    region = ENV['BUNNY_REGION']

    if storage_zone.nil? || access_key.nil? || secret_key.nil?
      puts "❌ ERROR: Missing Bunny.net credentials!"
      puts "   BUNNY_STORAGE_ZONE: #{storage_zone.present? ? '✓' : '✗ MISSING'}"
      puts "   BUNNY_ACCESS_KEY: #{access_key.present? ? '✓ (hidden)' : '✗ MISSING'}"
      puts "   BUNNY_SECRET_KEY: #{secret_key.present? ? '✓ (hidden)' : '✗ MISSING'}"
      puts "   BUNNY_REGION: #{region || 'de (default)'}"
      exit 1
    end

    puts "   ✓ BUNNY_STORAGE_ZONE: #{storage_zone}"
    puts "   ✓ BUNNY_ACCESS_KEY: #{access_key[0..10]}... (hidden)"
    puts "   ✓ BUNNY_SECRET_KEY: #{secret_key[0..10]}... (hidden)"
    puts "   ✓ BUNNY_REGION: #{region || 'de (default)'}"
    puts ""

    # Check Active Storage configuration
    puts "2️⃣ Checking Active Storage configuration:"
    service = Rails.application.config.active_storage.service
    puts "   Service: #{service}"

    if service != :bunny
      puts "   ⚠️  WARNING: Active Storage is not set to :bunny"
      puts "   Current: #{service}"
      puts "   Expected: :bunny"
    else
      puts "   ✓ Active Storage configured for Bunny.net"
    end
    puts ""

    # Test file upload
    puts "3️⃣ Testing file upload:"
    begin
      # Create a test file
      test_content = "Bunny.net test file created at #{Time.current}"
      filename = "test-#{Time.current.to_i}.txt"

      # Create a StringIO object to simulate a file
      require 'stringio'
      file = StringIO.new(test_content)

      # Upload using Active Storage
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: filename,
        content_type: 'text/plain'
      )

      puts "   ✓ File uploaded successfully!"
      puts "   - Blob ID: #{blob.id}"
      puts "   - Filename: #{blob.filename}"
      puts "   - Service: #{blob.service_name}"
      puts "   - Key: #{blob.key}"
      puts ""

      # Try to generate URL
      puts "4️⃣ Testing file URL generation:"
      url = Rails.application.routes.url_helpers.rails_blob_url(blob, host: 'localhost')
      puts "   ✓ URL generated: #{url}"
      puts ""

      # Check if file exists in storage
      puts "5️⃣ Verifying file exists in storage:"
      if blob.service.exist?(blob.key)
        puts "   ✓ File exists on Bunny.net!"
        puts ""

        # Clean up test file
        puts "6️⃣ Cleaning up test file:"
        blob.purge
        puts "   ✓ Test file removed"
        puts ""

        puts "✅ SUCCESS! Bunny.net storage is working correctly!"
        puts ""
        puts "Next steps:"
        puts "1. Upload images via /admin/images"
        puts "2. Check Bunny.net dashboard to verify files appear"
        puts "3. Verify images display correctly on your site"

      else
        puts "   ❌ File NOT found on Bunny.net!"
        puts "   This suggests upload failed or credentials are incorrect."
        blob.purge rescue nil
        exit 1
      end

    rescue => e
      puts "   ❌ ERROR during upload:"
      puts "   #{e.class}: #{e.message}"
      puts ""
      puts "   Full error:"
      puts e.backtrace.first(10).map { |line| "     #{line}" }.join("\n")
      puts ""
      puts "Troubleshooting:"
      puts "1. Verify credentials are correct in Bunny.net dashboard"
      puts "2. Check that storage zone '#{storage_zone}' exists"
      puts "3. Ensure the region is correct (currently: #{region || 'de'})"
      puts "4. Verify ReadOnly and Password are not swapped"
      exit 1
    end
  end
end
