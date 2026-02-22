class BunnyBrowser
  BASE_URL = "https://storage.bunnycdn.com"
  CDN_URL = "https://crypto-art.b-cdn.net"

  def initialize
    @access_key = Rails.application.credentials.dig(:bunny, :access_key)
    @storage_zone = Rails.application.credentials.dig(:bunny, :storage_zone) || "crypto-art"
  end

  # List files and directories at a given path.
  # Returns an array of hashes with file metadata.
  def list(path = "")
    path = sanitize_path(path)
    uri = URI("#{BASE_URL}/#{@storage_zone}/#{path}/")

    response = request(:get, uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "Bunny API error listing #{path}: #{response.code} #{response.body}"
    end
  end

  # Upload a file to the given path.
  def upload(path, filename, io, content_type = "application/octet-stream")
    path = sanitize_path(path)
    safe_filename = sanitize_filename(filename)
    full_path = path.empty? ? safe_filename : "#{path}/#{safe_filename}"
    uri = URI("#{BASE_URL}/#{@storage_zone}/#{full_path}")

    body = io.read
    response = request(:put, uri, body: body, content_type: content_type)

    if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)
      true
    else
      raise "Bunny API error uploading #{full_path}: #{response.code} #{response.body}"
    end
  end

  # Delete a file at the given path.
  def delete(path)
    path = sanitize_path(path)
    uri = URI("#{BASE_URL}/#{@storage_zone}/#{path}")

    response = request(:delete, uri)

    if response.is_a?(Net::HTTPSuccess)
      true
    else
      raise "Bunny API error deleting #{path}: #{response.code} #{response.body}"
    end
  end

  # Create a folder by uploading a placeholder and immediately deleting it.
  def create_folder(path)
    path = sanitize_path(path)
    placeholder = "#{path}/.folder"
    uri = URI("#{BASE_URL}/#{@storage_zone}/#{placeholder}")

    response = request(:put, uri, body: "", content_type: "application/octet-stream")

    if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)
      true
    else
      raise "Bunny API error creating folder #{path}: #{response.code} #{response.body}"
    end
  end

  # Build the public CDN URL for a file.
  def cdn_url(path)
    path = sanitize_path(path)
    "#{CDN_URL}/#{path}"
  end

  private

  def request(method, uri, body: nil, content_type: nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    case method
    when :get
      req = Net::HTTP::Get.new(uri)
    when :put
      req = Net::HTTP::Put.new(uri)
      req.body = body
      req["Content-Type"] = content_type if content_type
    when :delete
      req = Net::HTTP::Delete.new(uri)
    end

    req["AccessKey"] = @access_key
    req["Accept"] = "application/json"

    http.request(req)
  end

  def sanitize_path(path)
    return "" if path.blank?
    # Remove leading/trailing slashes and prevent directory traversal
    path.to_s.gsub(/\.\./, "").gsub(%r{^/+|/+$}, "")
  end

  def sanitize_filename(filename)
    filename.to_s.gsub(/\.\./, "").gsub(%r{[/\\]}, "")
  end
end
