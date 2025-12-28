class Admin::DashboardController < ApplicationController
  include Authentication
  before_action :require_authentication

  def index
    @total_images = Image.count
    @total_votes = Vote.count
    @total_sessions = VotingSession.count
    @total_invite_links = InviteLink.count
    @total_favorites = Favorite.count

    # Recent activity
    @recent_votes = Vote.includes(:winner, :loser).order(created_at: :desc).limit(10)

    # Top images
    @top_images = Image.ranked.limit(5)
  end
end
