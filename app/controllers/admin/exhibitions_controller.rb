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
      redirect_to admin_exhibitions_path, notice: "Exhibition updated successfully"
    else
      @spaces = Space.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exhibition.destroy
    redirect_to admin_exhibitions_path, notice: "Exhibition deleted successfully"
  end

  private

  def set_exhibition
    @exhibition = Exhibition.find_by!(slug: params[:id])
  end

  def exhibition_params
    params.require(:exhibition).permit(
      :title, :description, :space_id, :start_date, :end_date,
      :status, :slug, :luma_url, :manifold_url, :poap_url
    )
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
