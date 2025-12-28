class FavoritesController < ApplicationController
  allow_unauthenticated_access
  before_action :ensure_voting_session

  MINIMUM_VOTES = 26

  def index
    # Check if user has voted enough times
    votes_count = @voting_session.votes.count

    if votes_count < MINIMUM_VOTES && Setting.voting_open?
      redirect_to vote_path, alert: "Je moet nog #{MINIMUM_VOTES - votes_count} paren stemmen voordat je je top 5 kunt kiezen."
      return
    end

    # Get already selected favorites
    @selected_favorites = @voting_session.favorites.includes(:image).order(:position)
    @selected_image_ids = @selected_favorites.pluck(:image_id)

    # Get all images for selection, with selected ones first
    all_images = Image.ranked.with_attached_file.to_a
    selected_images = all_images.select { |img| @selected_image_ids.include?(img.id) }
    unselected_images = all_images.reject { |img| @selected_image_ids.include?(img.id) }
    @images = selected_images + unselected_images
  end

  def create
    # Get the selected image IDs from params
    # Handle both array and nil cases
    image_ids_param = params[:image_ids]
    if image_ids_param.nil?
      selected_ids = []
    elsif image_ids_param.is_a?(Array)
      selected_ids = image_ids_param.map(&:to_i).reject(&:zero?)
    else
      selected_ids = [image_ids_param.to_i].reject(&:zero?)
    end

    if selected_ids.size != 5
      redirect_to favorites_path, alert: "Selecteer exact 5 afbeeldingen (je hebt #{selected_ids.size} geselecteerd)."
      return
    end

    # Clear existing favorites for this session
    @voting_session.favorites.destroy_all

    # Create new favorites
    selected_ids.each_with_index do |image_id, index|
      @voting_session.favorites.create!(
        image_id: image_id,
        position: index + 1
      )
    end

    redirect_to results_path, notice: "Je top 5 is opgeslagen!"
  end

  private

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
end
