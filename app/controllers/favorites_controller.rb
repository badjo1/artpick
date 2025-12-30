class FavoritesController < ApplicationController
  allow_unauthenticated_access

  # Legacy controller - redirects to current active exhibition
  # Maintains backward compatibility for old URLs

  def index
    exhibition = Exhibition.active.first

    if exhibition
      redirect_to preferences_exhibition_path(exhibition)
    else
      redirect_to exhibitions_path, alert: "No active exhibition at the moment"
    end
  end

  def create
    exhibition = Exhibition.active.first

    if exhibition
      redirect_to preferences_exhibition_path(exhibition), method: :post
    else
      redirect_to exhibitions_path, alert: "No active exhibition at the moment"
    end
  end
end
