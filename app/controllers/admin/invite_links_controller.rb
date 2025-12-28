class Admin::InviteLinksController < ApplicationController
  include Authentication
  before_action :require_authentication

  def index
    @invite_links = InviteLink.order(created_at: :desc)
    @new_invite_link = InviteLink.new
  end

  def create
    @invite_link = InviteLink.new(invite_link_params)

    if @invite_link.save
      redirect_to admin_invite_links_path, notice: "Uitnodigingslink succesvol aangemaakt"
    else
      @invite_links = InviteLink.order(created_at: :desc)
      @new_invite_link = @invite_link
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @invite_link = InviteLink.find(params[:id])
    @invite_link.destroy
    redirect_to admin_invite_links_path, notice: "Uitnodigingslink succesvol verwijderd"
  end

  private

  def invite_link_params
    params.require(:invite_link).permit(:name, :active)
  end
end
