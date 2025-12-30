class SpacesController < ApplicationController
  allow_unauthenticated_access

  def index
    @spaces = Space.includes(:exhibitions).all
  end

  def show
    @space = Space.includes(exhibitions: :artworks, screens: :exhibition).find(params[:id])
    @exhibitions = @space.exhibitions.order(start_date: :desc)
    @screens = @space.screens.active
    @total_artworks = @space.artworks.count
  end
end
