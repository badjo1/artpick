class VotingController < ApplicationController
  allow_unauthenticated_access
  before_action :check_voting_open
  before_action :ensure_voting_session

  MINIMUM_VOTES = 26

  def index
    # Check if voting is still open, otherwise redirect to results
    unless Setting.voting_open?
      redirect_to results_path
      return
    end

    # Get vote count for this session
    @votes_count = @voting_session.votes.count
    @minimum_votes = MINIMUM_VOTES
    @votes_remaining = [@minimum_votes - @votes_count, 0].max
    @minimum_reached = @votes_count >= @minimum_votes

    # Get a random pair of images that hasn't been seen by this session
    @pair = get_random_pair

    if @pair.nil?
      # All pairs have been seen, show completion message
      @all_pairs_seen = true
    end
  end

  def vote
    winner_id = params[:winner_id].to_i
    loser_id = params[:loser_id].to_i

    # Validate that both images exist
    winner = Image.find_by(id: winner_id)
    loser = Image.find_by(id: loser_id)

    if winner.nil? || loser.nil?
      redirect_to vote_path, alert: "Ongeldige afbeeldingen"
      return
    end

    # Create the vote
    vote = Vote.new(
      winner_id: winner_id,
      loser_id: loser_id,
      voting_session_id: @voting_session.id,
      invite_link_id: session[:invite_link_id]
    )

    if vote.save
      @voting_session.touch_activity
      redirect_to vote_path
    else
      redirect_to vote_path, alert: "Er is iets misgegaan bij het opslaan van je stem"
    end
  end

  private

  def check_voting_open
    # This will be checked in the index action as well
    # but we set a flag here for consistency
    @voting_open = Setting.voting_open?
  end

  def ensure_voting_session
    # Get or create a voting session for this user
    session_token = session[:voting_session_token]

    if session_token
      @voting_session = VotingSession.find_by(session_token: session_token)
    end

    unless @voting_session
      @voting_session = VotingSession.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        last_activity: Time.current
      )
      session[:voting_session_token] = @voting_session.session_token
    end
  end

  def get_random_pair
    # Get all images
    all_images = Image.all.to_a

    # If there are less than 2 images, we can't make a pair
    return nil if all_images.size < 2

    # Get all possible pairs
    all_pairs = all_images.combination(2).to_a

    # Filter out pairs that have been seen by this session
    unseen_pairs = all_pairs.reject do |pair|
      @voting_session.has_seen_pair?(pair[0].id, pair[1].id)
    end

    # If no unseen pairs, return nil
    return nil if unseen_pairs.empty?

    # Return a random unseen pair
    unseen_pairs.sample
  end
end
