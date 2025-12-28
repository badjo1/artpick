class ResultsController < ApplicationController
  allow_unauthenticated_access

  MINIMUM_VOTES = 26

  def index
    # Check if user has voted enough times
    voting_session = get_voting_session

    if voting_session
      votes_count = voting_session.votes.count

      # Redirect to voting if minimum not reached and voting is still open
      if votes_count < MINIMUM_VOTES && Setting.voting_open?
        redirect_to vote_path, alert: "Je moet nog #{MINIMUM_VOTES - votes_count} paren stemmen voordat je de resultaten kunt zien."
        return
      end
    elsif Setting.voting_open?
      # No session yet, redirect to voting
      redirect_to vote_path, alert: "Stem op minimaal #{MINIMUM_VOTES} paren om de resultaten te zien."
      return
    end

    # Get all images ranked by Elo score
    @images = Image.ranked.with_attached_file

    # Get top 10
    @top_10 = @images.limit(10)

    # Get intro text from settings
    @intro_text = Setting.results_intro

    # Check if voting is still open
    @voting_open = Setting.voting_open?

    # Check if user has selected their top 5
    if voting_session
      @has_selected_favorites = voting_session.favorites.count == 5
    else
      @has_selected_favorites = false
    end
  end

  private

  def get_voting_session
    session_token = session[:voting_session_token]
    return nil unless session_token
    VotingSession.find_by(session_token: session_token)
  end
end
