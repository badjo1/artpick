class Admin::StorageController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin

  def index
    @path = sanitize_path(params[:path])
    @browser = BunnyBrowser.new
    @entries = @browser.list(@path)

    # Sort: directories first, then files, alphabetically
    @entries.sort_by! { |e| [e["IsDirectory"] ? 0 : 1, e["ObjectName"].downcase] }
  rescue => e
    flash.now[:alert] = "Could not list files: #{e.message}"
    @entries = []
  end

  def upload
    path = sanitize_path(params[:path])
    browser = BunnyBrowser.new
    files = Array(params[:files])
    uploaded = 0

    files.each do |file|
      next unless file.respond_to?(:original_filename)
      browser.upload(path, file.original_filename, file, file.content_type)
      uploaded += 1
    end

    redirect_to admin_storage_index_path(path: path), notice: "#{uploaded} file(s) uploaded."
  rescue => e
    redirect_to admin_storage_index_path(path: path), alert: "Upload failed: #{e.message}"
  end

  def create_folder
    path = sanitize_path(params[:path])
    folder_name = params[:folder_name].to_s.strip
    browser = BunnyBrowser.new

    if folder_name.blank?
      redirect_to admin_storage_index_path(path: path), alert: "Folder name cannot be blank."
      return
    end

    full_path = path.present? ? "#{path}/#{folder_name}" : folder_name
    browser.create_folder(full_path)

    redirect_to admin_storage_index_path(path: path), notice: "Folder '#{folder_name}' created."
  rescue => e
    redirect_to admin_storage_index_path(path: path), alert: "Could not create folder: #{e.message}"
  end

  def destroy
    file_path = sanitize_path(params[:path])
    return_path = File.dirname(file_path)
    return_path = "" if return_path == "."
    browser = BunnyBrowser.new

    browser.delete(file_path)

    redirect_to admin_storage_index_path(path: return_path), notice: "File deleted."
  rescue => e
    redirect_to admin_storage_index_path(path: return_path), alert: "Could not delete: #{e.message}"
  end

  helper_method :image_file?, :video_file?, :media_file?

  private

  def image_file?(name)
    name.to_s.match?(/\.(jpe?g|png|gif|webp|svg|bmp|ico)$/i)
  end

  def video_file?(name)
    name.to_s.match?(/\.(mp4|mov|webm|avi|mkv)$/i)
  end

  def media_file?(name)
    image_file?(name) || video_file?(name)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end

  def sanitize_path(path)
    return "" if path.blank?
    path.to_s.gsub(/\.\./, "").gsub(%r{^/+|/+$}, "")
  end
end
