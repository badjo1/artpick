class Admin::ExhibitionsController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin
  before_action :set_exhibition, only: [:show, :edit, :update, :destroy]

  def index
    @exhibitions = Exhibition.includes(:space).order(start_date: :desc)
    @active_count = Exhibition.active.count
    @upcoming_count = Exhibition.upcoming.count
    @archived_count = Exhibition.archived.count
  end

  def show
    @artworks = @exhibition.artworks.ranked(@exhibition)
    @comparisons_count = @exhibition.comparisons.count
    @preferences_count = @exhibition.preferences.count
    @check_ins_count = @exhibition.check_ins.count
  end

  def new
    @exhibition = Exhibition.new
    @spaces = Space.all
  end

  def create
    @exhibition = Exhibition.new(exhibition_params)

    if @exhibition.save
      redirect_to admin_exhibitions_path, notice: "Exhibition created successfully"
    else
      @spaces = Space.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @spaces = Space.all
  end

  def update
    if @exhibition.update(exhibition_params)
      flash[:notice] = "Exhibition updated successfully"
      redirect_to admin_exhibitions_path
    else
      @spaces = Space.all
      flash.now[:alert] = "Failed to update exhibition: #{@exhibition.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @exhibition.destroy
      redirect_to admin_exhibitions_path, notice: "Exhibition deleted successfully"
    else
      redirect_to admin_exhibitions_path, alert: "Cannot delete exhibition: #{@exhibition.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_exhibition
    # Handle both numeric IDs and slugs
    @exhibition = if params[:id].to_i.to_s == params[:id]
      Exhibition.find(params[:id])
    else
      Exhibition.find_by!(slug: params[:id])
    end
  end

  def exhibition_params
    params.require(:exhibition).permit(
      :title, :number, :description, :space_id, :start_date, :end_date,
      :status, :slug, :voting_enabled, :cover_image, :luma_url, :manifold_url, :poap_url
    )
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
