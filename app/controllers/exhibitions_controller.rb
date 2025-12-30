class ExhibitionsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_exhibition, except: [:index]
  before_action :ensure_voting_session, only: [:comparison, :compare, :preferences]

  MINIMUM_COMPARISONS = 26

  def index
    @exhibitions = Exhibition.includes(:space).order(start_date: :desc)
    @active_exhibitions = @exhibitions.active
    @upcoming_exhibitions = @exhibitions.upcoming
    @archived_exhibitions = @exhibitions.archived
  end

  def show
    @top_artworks = @exhibition.top_artworks(10)
    @artworks_count = @exhibition.artworks.count
    @comparisons_count = @exhibition.comparisons.count

    # Get personal rankings if voting session exists
    if session[:voting_session_token]
      @voting_session = VotingSession.find_by(session_token: session[:voting_session_token])
      if @voting_session
        @personal_top_artworks = @voting_session.personal_top_artworks(5)
        @session_comparisons_count = @voting_session.comparisons.where(exhibition: @exhibition).count
        @has_voted = @session_comparisons_count > 0
      end
    end

    # Log check-in
    CheckIn.log('view', @exhibition,
                user: Current.user,
                voting_session: @voting_session,
                exhibition: @exhibition,
                ip_address: request.remote_ip,
                user_agent: request.user_agent)
  end

  def artworks
    @artworks = @exhibition.artworks.includes(:artist).ranked(@exhibition)
  end

  def comparison
    unless @exhibition.voting_open?
      redirect_to exhibition_path(@exhibition), alert: "Voting is closed for this exhibition"
      return
    end

    @comparisons_count = @voting_session.comparisons.where(exhibition: @exhibition).count
    @pair = get_random_pair

    unless @pair
      redirect_to preferences_exhibition_path(@exhibition), notice: "You've seen all possible pairs! Select your top 5."
      return
    end

    # Log comparison start
    CheckIn.log('comparison_start', @exhibition,
                user: Current.user,
                voting_session: @voting_session,
                exhibition: @exhibition,
                ip_address: request.remote_ip,
                user_agent: request.user_agent,
                metadata: { artworks: @pair.map(&:id) })
  end

  def compare
    winning_artwork = @exhibition.artworks.find(params[:winning_artwork_id])
    losing_artwork = @exhibition.artworks.find(params[:losing_artwork_id])

    Comparison.create!(
      winning_artwork: winning_artwork,
      losing_artwork: losing_artwork,
      exhibition: @exhibition,
      user: Current.user,
      voting_session: @voting_session
    )

    @voting_session.touch_activity

    redirect_to comparison_exhibition_path(@exhibition)
  end

  def preferences
    @comparisons_count = @voting_session.comparisons.where(exhibition: @exhibition).count

    if @comparisons_count < MINIMUM_COMPARISONS
      redirect_to comparison_exhibition_path(@exhibition),
                  alert: "Please make at least #{MINIMUM_COMPARISONS} comparisons before selecting your top 5"
      return
    end

    if request.post?
      handle_preferences_submission
    else
      @top_artworks = @exhibition.artworks.ranked(@exhibition).limit(20)
      @current_preferences = @voting_session.preferences.where(exhibition: @exhibition).includes(:artwork).ordered
    end
  end

  private

  def set_exhibition
    @exhibition = Exhibition.includes(:space).find_by!(slug: params[:slug])
  end

  def ensure_voting_session
    @voting_session = VotingSession.find_by(session_token: session[:voting_session_token])

    if @voting_session.nil?
      @voting_session = VotingSession.create!(
        session_token: SecureRandom.hex(32),
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      session[:voting_session_token] = @voting_session.session_token
    else
      @voting_session.touch_activity
    end
  end

  def get_random_pair
    artwork_ids = @exhibition.artworks.pluck(:id)
    return nil if artwork_ids.size < 2

    seen_pairs = @voting_session.comparisons
                                .where(exhibition: @exhibition)
                                .pluck(:winning_artwork_id, :losing_artwork_id)
                                .map(&:sort)

    # Generate all possible pairs
    all_pairs = artwork_ids.combination(2).to_a

    # Filter out seen pairs
    unseen_pairs = all_pairs.reject { |pair| seen_pairs.include?(pair.sort) }

    return nil if unseen_pairs.empty?

    # Pick a random unseen pair
    selected_pair = unseen_pairs.sample
    @exhibition.artworks.where(id: selected_pair).to_a.shuffle
  end

  def handle_preferences_submission
    # Remove existing preferences for this session and exhibition
    @voting_session.preferences.where(exhibition: @exhibition).destroy_all

    # Create new preferences
    params[:artwork_ids]&.each_with_index do |artwork_id, index|
      next if artwork_id.blank?

      Preference.create!(
        artwork_id: artwork_id,
        exhibition: @exhibition,
        voting_session: @voting_session,
        user: Current.user,
        position: index + 1
      )
    end

    # Log completion
    CheckIn.log('comparison_complete', @exhibition,
                user: Current.user,
                voting_session: @voting_session,
                exhibition: @exhibition,
                ip_address: request.remote_ip,
                user_agent: request.user_agent,
                metadata: { preferences_count: params[:artwork_ids]&.compact&.size || 0 })

    redirect_to exhibition_path(@exhibition), notice: "Thank you for voting!"
  end
end
