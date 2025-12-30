class ArtistsController < ApplicationController
  allow_unauthenticated_access

  def index
    @artists = Artist.includes(:artworks).with_artworks.ordered_by_name
  end

  def show
    @artist = Artist.includes(artworks: [:exhibition]).find(params[:id])
    @artworks = @artist.artworks.includes(:exhibition).order(created_at: :desc)
    @exhibitions = @artist.exhibitions.distinct.order(start_date: :desc)
  end
end
