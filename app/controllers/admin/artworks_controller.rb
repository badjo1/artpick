class Admin::ArtworksController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin
  before_action :set_exhibition
  before_action :set_artwork, only: [:edit, :update, :destroy]

  def index
    @artworks = @exhibition.artworks.includes(:artist).ranked(@exhibition)
  end

  def new
    @artwork = @exhibition.artworks.new
    @artists = Artist.ordered_by_name
  end

  def create
    @artwork = @exhibition.artworks.new(artwork_params)

    if @artwork.save
      redirect_to admin_exhibition_artworks_path(@exhibition), notice: "Artwork created successfully"
    else
      @artists = Artist.ordered_by_name
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_new
    @artists = Artist.ordered_by_name
  end

  def bulk_create
    uploaded_files = params[:files]

    if uploaded_files.blank?
      redirect_to bulk_new_admin_exhibition_artworks_path(@exhibition), alert: "No files selected"
      return
    end

    uploaded_files = [uploaded_files] unless uploaded_files.is_a?(Array)

    success_count = 0
    errors = []

    # Get artist_id if provided
    artist_id = params[:artist_id].presence

    uploaded_files.each do |file|
      next if file.blank? || !file.respond_to?(:original_filename)

      # Generate title from filename
      title = File.basename(file.original_filename, ".*").gsub(/[_-]/, " ").titleize

      artwork = @exhibition.artworks.new(
        title: title,
        artist_id: artist_id
      )
      artwork.file.attach(file)

      if artwork.save
        success_count += 1
      else
        errors << "#{file.original_filename}: #{artwork.errors.full_messages.join(', ')}"
      end
    end

    # Update exhibition artwork_count
    @exhibition.update_column(:artwork_count, @exhibition.artworks.count)

    if errors.empty? && success_count > 0
      redirect_to admin_exhibition_artworks_path(@exhibition), notice: "#{success_count} artwork(s) uploaded successfully"
    elsif success_count > 0
      flash[:alert] = "#{success_count} artwork(s) uploaded. Errors: #{errors.join('; ')}"
      redirect_to bulk_new_admin_exhibition_artworks_path(@exhibition)
    else
      redirect_to bulk_new_admin_exhibition_artworks_path(@exhibition), alert: "Upload error: #{errors.join('; ')}"
    end
  end

  def edit
    @artists = Artist.ordered_by_name
  end

  def update
    if @artwork.update(artwork_params)
      redirect_to admin_exhibition_artworks_path(@exhibition), notice: "Artwork updated successfully"
    else
      @artists = Artist.ordered_by_name
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artwork.destroy

    # Update exhibition artwork_count
    @exhibition.update_column(:artwork_count, @exhibition.artworks.count)

    redirect_to admin_exhibition_artworks_path(@exhibition), notice: "Artwork deleted successfully"
  end

  private

  def set_exhibition
    # Accept both ID and slug for admin routes
    @exhibition = Exhibition.find_by(id: params[:exhibition_id]) ||
                  Exhibition.find_by!(slug: params[:exhibition_id])
  end

  def set_artwork
    @artwork = @exhibition.artworks.find(params[:id])
  end

  def artwork_params
    params.require(:artwork).permit(:title, :description, :artist_id, :year, :medium, :file)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
