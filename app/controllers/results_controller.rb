class ResultsController < ApplicationController
  allow_unauthenticated_access

  # Legacy controller - redirects to current active exhibition
  # Maintains backward compatibility for old URLs

  def index
    exhibition = Exhibition.active.first

    if exhibition
      redirect_to exhibition_path(exhibition)
    else
      # If no active exhibition, show the most recent archived one
      exhibition = Exhibition.archived.order(start_date: :desc).first
      if exhibition
        redirect_to exhibition_path(exhibition)
      else
        redirect_to exhibitions_path, alert: "No exhibitions available"
      end
    end
  end
end
