class InvitesController < ApplicationController
  allow_unauthenticated_access

  def show
    @invite_link = InviteLink.find_by(token: params[:token])

    if @invite_link.nil?
      redirect_to root_path, alert: "Uitnodiging niet gevonden"
      return
    end

    unless @invite_link.active?
      redirect_to root_path, alert: "Deze uitnodiging is niet meer actief"
      return
    end

    # Store the invite link ID in the session
    session[:invite_link_id] = @invite_link.id

    # Redirect to voting page
    redirect_to vote_path
  end
end
