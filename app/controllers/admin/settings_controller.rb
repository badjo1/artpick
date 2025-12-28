class Admin::SettingsController < ApplicationController
  include Authentication
  before_action :require_authentication

  def edit
    @voting_deadline = Setting.voting_deadline
    @results_intro = Setting.results_intro
  end

  def update
    Setting.set_value("voting_deadline", params[:voting_deadline]) if params[:voting_deadline].present?
    Setting.set_value("results_intro", params[:results_intro]) if params[:results_intro].present?

    redirect_to edit_admin_settings_path, notice: "Instellingen succesvol bijgewerkt"
  end
end
