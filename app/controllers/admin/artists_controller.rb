class Admin::ArtistsController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin
  before_action :set_artist, only: [:show, :edit, :update, :destroy]

  def index
    @artists = Artist.includes(:artworks).ordered_by_name
  end

  def show
    @artworks = @artist.artworks.includes(:exhibition).order(created_at: :desc)
    @exhibitions = @artist.exhibitions.distinct.order(start_date: :desc)
  end

  def new
    @artist = Artist.new
  end

  def create
    @artist = Artist.new(artist_params)

    if @artist.save
      redirect_to admin_artist_path(@artist), notice: "Artist created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @artist.update(artist_params)
      redirect_to admin_artist_path(@artist), notice: "Artist updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @artist.artworks.any?
      redirect_to admin_artist_path(@artist), alert: "Cannot delete artist with artworks. Reassign artworks first."
    else
      @artist.destroy
      redirect_to admin_artists_path, notice: "Artist deleted successfully"
    end
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def artist_params
    params.require(:artist).permit(:name, :bio, :website_url, :twitter_handle, :instagram_handle)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
