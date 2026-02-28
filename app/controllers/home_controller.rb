class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @exhibitions = Exhibition.includes(:space).order(start_date: :desc)
    @active_exhibitions = @exhibitions.active
    @upcoming_exhibitions = @exhibitions.upcoming
    @archived_exhibitions = @exhibitions.archived.limit(3)

    # Stats for The Continuum
    @total_artworks = Artwork.count
    @total_artists = Artist.joins(:artworks).distinct.count
    @total_exhibitions = Exhibition.count
  end
end
