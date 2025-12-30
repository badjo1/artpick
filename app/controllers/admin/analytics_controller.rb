class Admin::AnalyticsController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin

  def index
    # Overall analytics
    @total_check_ins = CheckIn.count
    @total_comparisons = Comparison.count
    @total_preferences = Preference.count
    @total_artworks = Artwork.count
    @total_exhibitions = Exhibition.count

    # Check-ins by action type
    @check_ins_by_action = CheckIn.group(:action_type).count

    # Recent activity (last 7 days)
    @recent_check_ins = CheckIn.where("created_at >= ?", 7.days.ago).count
    @recent_comparisons = Comparison.where("created_at >= ?", 7.days.ago).count

    # Active voting sessions (last 24 hours)
    @active_sessions = VotingSession.where("last_activity >= ?", 24.hours.ago).count

    # Exhibition breakdown
    @exhibitions = Exhibition.includes(:space).order(start_date: :desc).map do |exhibition|
      {
        exhibition: exhibition,
        check_ins: exhibition.check_ins.count,
        comparisons: exhibition.comparisons.count,
        preferences: exhibition.preferences.count,
        artworks: exhibition.artworks.count
      }
    end
  end

  def exhibition
    @exhibition = Exhibition.includes(:space, :artworks).find(params[:id])

    # Exhibition-specific stats
    @check_ins = @exhibition.check_ins.group(:action_type).count
    @comparisons_count = @exhibition.comparisons.count
    @preferences_count = @exhibition.preferences.count
    @unique_sessions = @exhibition.comparisons.select(:voting_session_id).distinct.count

    # Top artworks in this exhibition
    @top_artworks = @exhibition.artworks.ranked(@exhibition).limit(10)

    # Most favorited artworks
    @most_favorited = @exhibition.artworks
                                 .left_joins(:preferences)
                                 .group('artworks.id')
                                 .select('artworks.*, COUNT(preferences.id) as preferences_count')
                                 .order('preferences_count DESC')
                                 .limit(10)
  end

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
