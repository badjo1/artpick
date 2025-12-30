class Admin::SettingsController < ApplicationController
  layout "admin"
  include Authentication
  before_action :require_authentication
  before_action :set_setting, only: [:edit, :update, :destroy]

  def index
    @settings = Setting.all
  end

  def edit
  end

  def update
    if @setting.update(setting_params)
      redirect_to admin_settings_path, notice: "Setting updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @setting.destroy
    redirect_to admin_settings_path, notice: "Setting deleted successfully"
  end

  private

  def set_setting
    @setting = Setting.find(params[:id])
  end

  def setting_params
    params.require(:setting).permit(:key, :value, :setting_type, :exhibition_id)
  end
end
