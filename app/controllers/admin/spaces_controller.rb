class Admin::SpacesController < ApplicationController
  layout "admin"
  before_action :require_authentication
  before_action :require_admin
  before_action :set_space, only: [:show, :edit, :update, :destroy]

  def index
    @spaces = Space.includes(:exhibitions, :screens).all
  end

  def show
    @exhibitions = @space.exhibitions.order(start_date: :desc)
    @screens = @space.screens.includes(:exhibition)
  end

  def new
    @space = Space.new
  end

  def create
    @space = Space.new(space_params)

    if @space.save
      redirect_to admin_space_path(@space), notice: "Space created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @space.update(space_params)
      redirect_to admin_space_path(@space), notice: "Space updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @space.exhibitions.any?
      redirect_to admin_space_path(@space), alert: "Cannot delete space with exhibitions. Delete exhibitions first."
    else
      @space.destroy
      redirect_to admin_spaces_path, notice: "Space deleted successfully"
    end
  end

  private

  def set_space
    @space = Space.find(params[:id])
  end

  def space_params
    params.require(:space).permit(:name, :description, :location, :website_url)
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
