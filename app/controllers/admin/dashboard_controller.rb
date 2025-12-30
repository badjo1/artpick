class Admin::DashboardController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin

  def index
    # Overall platform stats
    @total_exhibitions = Exhibition.count
    @total_artworks = Artwork.count
    @total_artists = Artist.count
    @total_spaces = Space.count
    @total_comparisons = Comparison.count
    @total_preferences = Preference.count
    @total_sessions = VotingSession.count
    @total_invite_links = InviteLink.count
    @total_check_ins = CheckIn.count

    # Exhibition breakdown
    @active_exhibitions = Exhibition.active.includes(:space)
    @upcoming_exhibitions = Exhibition.upcoming.includes(:space).limit(3)
    @recent_archived = Exhibition.archived.includes(:space).order(start_date: :desc).limit(3)

    # Recent activity
    @recent_comparisons = Comparison.includes(:winning_artwork, :losing_artwork, :exhibition)
                                    .order(created_at: :desc)
                                    .limit(10)

    @recent_check_ins = CheckIn.includes(:checkable, :exhibition)
                               .order(created_at: :desc)
                               .limit(10)

    # Active sessions (last 24 hours)
    @active_sessions_count = VotingSession.active.count

    # Quick links to most active exhibition
    @most_active_exhibition = Exhibition.active.first || Exhibition.order(start_date: :desc).first
  end

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
