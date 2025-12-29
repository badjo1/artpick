#!/usr/bin/env ruby
# Standalone Bunny.net test script
# Run with: ruby test_bunny_direct.rb

require 'bundler/setup'
require 'aws-sdk-s3'
require 'stringio'

puts "🧪 Direct Bunny.net Connection Test"
puts "=" * 50
puts ""

# HARDCODED CREDENTIALS (TEMPORARY - ROTATE AFTER TEST!)
STORAGE_ZONE = 'crypto-art'
ACCESS_KEY = 'b471446c-1280-4c8b-b5b46069e722-3016-48f2'  # Password (write access!)
SECRET_KEY = 'b471446c-1280-4c8b-b5b46069e722-3016-48f2'  # Password (same for secret)
ENDPOINT = 'https://storage.bunnycdn.com'
REGION = 'us-east-1'  # Dummy region for S3 SDK

puts "Configuration:"
puts "  Storage Zone: #{STORAGE_ZONE}"
puts "  Access Key: #{ACCESS_KEY[0..15]}..."
puts "  Secret Key: #{SECRET_KEY[0..15]}..."
puts "  Endpoint: #{ENDPOINT}"
puts "  Region: #{REGION}"
puts ""

begin
  puts "1️⃣ Creating S3 client..."

  s3_client = Aws::S3::Client.new(
    access_key_id: ACCESS_KEY,
    secret_access_key: SECRET_KEY,
    region: REGION,
    endpoint: ENDPOINT,
    force_path_style: true
  )

  puts "   ✓ S3 client created"
  puts ""

  puts "2️⃣ Testing connection (list objects)..."

  begin
    response = s3_client.list_objects_v2(
      bucket: STORAGE_ZONE,
      max_keys: 5
    )

    puts "   ✓ Connection successful!"
    puts "   Found #{response.contents.size} objects in bucket"

    if response.contents.any?
      puts ""
      puts "   Existing files:"
      response.contents.first(5).each do |obj|
        puts "     - #{obj.key} (#{obj.size} bytes)"
      end
    end
  rescue Aws::S3::Errors::ServiceError => e
    puts "   ✗ List objects failed: #{e.class} - #{e.message}"
    puts ""
    puts "   This might be OK if using ReadOnly password for access_key"
    puts "   Continuing to upload test..."
  end

  puts ""
  puts "3️⃣ Creating test file..."

  test_filename = "bunny-test-#{Time.now.to_i}.txt"
  test_content = "Bunny.net test file\nCreated at: #{Time.now}\nFrom: ArtPick app test"
  test_file = StringIO.new(test_content)

  puts "   ✓ Test file: #{test_filename}"
  puts "   ✓ Size: #{test_content.bytesize} bytes"
  puts ""

  puts "4️⃣ Uploading to Bunny.net..."

  s3_client.put_object(
    bucket: STORAGE_ZONE,
    key: test_filename,
    body: test_file,
    content_type: 'text/plain'
  )

  puts "   ✓ Upload successful!"
  puts ""

  puts "5️⃣ Verifying upload..."

  head_response = s3_client.head_object(
    bucket: STORAGE_ZONE,
    key: test_filename
  )

  puts "   ✓ File exists on Bunny.net!"
  puts "   - Size: #{head_response.content_length} bytes"
  puts "   - Type: #{head_response.content_type}"
  puts "   - ETag: #{head_response.etag}"
  puts ""

  puts "6️⃣ Generating public URL..."

  public_url = "https://#{STORAGE_ZONE}.b-cdn.net/#{test_filename}"
  puts "   URL: #{public_url}"
  puts ""
  puts "   (Note: This URL will work if you have a Pull Zone configured)"
  puts "   Direct storage URL: #{ENDPOINT}/#{STORAGE_ZONE}/#{test_filename}"
  puts ""

  puts "7️⃣ Cleaning up test file..."

  s3_client.delete_object(
    bucket: STORAGE_ZONE,
    key: test_filename
  )

  puts "   ✓ Test file deleted"
  puts ""

  puts "=" * 50
  puts "✅ SUCCESS! Bunny.net storage is working perfectly!"
  puts "=" * 50
  puts ""
  puts "Next steps:"
  puts "1. Deploy the fixed storage.yml to production"
  puts "2. Restart production server"
  puts "3. Upload images via admin interface"
  puts "4. IMPORTANT: Rotate your Bunny.net credentials!"
  puts ""

rescue Aws::S3::Errors::ServiceError => e
  puts ""
  puts "=" * 50
  puts "❌ AWS S3 Error"
  puts "=" * 50
  puts ""
  puts "Error Class: #{e.class}"
  puts "Error Code: #{e.code}" if e.respond_to?(:code)
  puts "Message: #{e.message}"
  puts ""
  puts "Troubleshooting:"
  puts "- Verify storage zone 'crypto-art' exists in Bunny.net"
  puts "- Check credentials are not swapped"
  puts "- Ensure storage zone is not 'private'"
  puts "- Try regenerating passwords in Bunny.net dashboard"

  exit 1

rescue StandardError => e
  puts ""
  puts "=" * 50
  puts "❌ Unexpected Error"
  puts "=" * 50
  puts ""
  puts "Error: #{e.class}"
  puts "Message: #{e.message}"
  puts ""
  puts "Backtrace:"
  puts e.backtrace.first(10).map { |line| "  #{line}" }.join("\n")

  exit 1
end
