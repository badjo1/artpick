#!/usr/bin/env ruby
# Test script for active_storage_bunny gem
# Run with: ruby test_bunny_gem.rb

require_relative 'config/environment'
require 'stringio'

puts "🧪 Testing Bunny.net with active_storage_bunny gem"
puts "=" * 50
puts ""

# HARDCODED CREDENTIALS (TEMPORARY - ROTATE AFTER TEST!)
STORAGE_ZONE = 'crypto-art'
ACCESS_KEY = 'b471446c-1280-4c8b-b5b46069e722-3016-48f2'  # Password (write access needed for uploads)
SECRET_KEY = '1977bcde-e5bc-4907-8c619c8fcb57-ffba-4ad1'  # ReadOnly Password (used for cache purging)
REGION = nil  # nil for Falkenstein (de) - uses default endpoint storage.bunnycdn.com

puts "Configuration:"
puts "  Storage Zone: #{STORAGE_ZONE}"
puts "  Access Key: #{ACCESS_KEY[0..15]}..."
puts "  Secret Key: #{SECRET_KEY[0..15]}..."
puts "  Region: #{REGION}"
puts ""

begin
  puts "1️⃣ Creating Bunny storage service..."

  service = ActiveStorage::Service::BunnyService.new(
    access_key: ACCESS_KEY,
    api_key: SECRET_KEY,
    storage_zone: STORAGE_ZONE,
    region: REGION
  )

  puts "   ✓ Service created"
  puts ""

  puts "2️⃣ Creating test file..."

  test_content = "Bunny.net test file\nCreated at: #{Time.now}\nFrom: ArtPick app test via active_storage_bunny gem"
  test_file = StringIO.new(test_content)
  test_key = "test-gem-#{Time.now.to_i}.txt"

  puts "   ✓ Test file: #{test_key}"
  puts "   ✓ Size: #{test_content.bytesize} bytes"
  puts ""

  puts "3️⃣ Uploading to Bunny.net..."

  service.upload(
    test_key,
    test_file,
    checksum: nil,
    content_type: 'text/plain'
  )

  puts "   ✓ Upload successful!"
  puts ""

  puts "4️⃣ Verifying upload..."

  if service.exist?(test_key)
    puts "   ✓ File exists on Bunny.net!"
    puts ""

    puts "5️⃣ Generating public URL..."

    url = service.url(test_key, expires_in: 5.minutes, disposition: :inline, filename: test_key)
    puts "   URL: #{url}"
    puts ""

    puts "6️⃣ Cleaning up test file..."

    service.delete(test_key)
    puts "   ✓ Test file deleted"
    puts ""

    puts "=" * 50
    puts "✅ SUCCESS! active_storage_bunny gem is working!"
    puts "=" * 50
    puts ""
    puts "Next steps:"
    puts "1. Deploy deze configuratie naar productie"
    puts "2. Zorg dat environment variabelen correct zijn:"
    puts "   - BUNNY_STORAGE_ZONE=#{STORAGE_ZONE}"
    puts "   - BUNNY_ACCESS_KEY=<Password> (write access needed!)"
    puts "   - BUNNY_SECRET_KEY=<ReadOnly Password> (cache purging)"
    puts "   - BUNNY_REGION= (leave empty for Falkenstein/de)"
    puts "3. Restart productie server"
    puts "4. Upload afbeeldingen via admin interface"
    puts "5. BELANGRIJK: Roteer je Bunny.net credentials!"
    puts ""

  else
    puts "   ❌ File NOT found on Bunny.net!"
    puts "   Upload lijkt mislukt te zijn."
    exit 1
  end

rescue => e
  puts ""
  puts "=" * 50
  puts "❌ Error"
  puts "=" * 50
  puts ""
  puts "Error: #{e.class}"
  puts "Message: #{e.message}"
  puts ""
  puts "Backtrace:"
  puts e.backtrace.first(10).map { |line| "  #{line}" }.join("\n")
  puts ""
  puts "Troubleshooting:"
  puts "- Verify storage zone 'crypto-art' exists in Bunny.net"
  puts "- Check credentials are correct (ReadOnly vs Password)"
  puts "- Ensure storage zone is not 'private'"
  puts "- Check region is correct (currently: #{REGION})"

  exit 1
end
