class Admin::ScreensController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin
  before_action :set_space
  before_action :set_screen, only: [:edit, :update, :destroy]

  def index
    @screens = @space.screens.includes(:exhibition).order(:screen_number)
  end

  def new
    @screen = @space.screens.new
    @exhibitions = Exhibition.where(space: @space).order(start_date: :desc)
  end

  def create
    @screen = @space.screens.new(screen_params)

    if @screen.save
      redirect_to admin_space_screens_path(@space), notice: "Screen created successfully"
    else
      @exhibitions = Exhibition.where(space: @space).order(start_date: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @exhibitions = Exhibition.where(space: @space).order(start_date: :desc)
  end

  def update
    if @screen.update(screen_params)
      redirect_to admin_space_screens_path(@space), notice: "Screen updated successfully"
    else
      @exhibitions = Exhibition.where(space: @space).order(start_date: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @screen.destroy
    redirect_to admin_space_screens_path(@space), notice: "Screen deleted successfully"
  end

  private

  def set_space
    @space = Space.find(params[:space_id])
  end

  def set_screen
    @screen = @space.screens.find(params[:id])
  end

  def screen_params
    params.require(:screen).permit(:name, :screen_number, :location_description, :exhibition_id, :active)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
