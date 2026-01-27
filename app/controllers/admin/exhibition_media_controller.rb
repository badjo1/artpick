class Admin::ExhibitionMediaController < ApplicationController
  before_action :require_authentication
  before_action :require_admin
  before_action :set_exhibition
  before_action :set_exhibition_medium, only: [:edit, :update, :destroy]

  def index
    @exhibition_media = @exhibition.exhibition_media.positioned
  end

  def new
    @exhibition_medium = @exhibition.exhibition_media.new
  end

  def create
    uploaded_file = params[:exhibition_medium]&.delete(:file)
    @exhibition_medium = @exhibition.exhibition_media.new(exhibition_medium_params)

    if uploaded_file.present?
      blob = ExhibitionMedium.create_blob_with_key(@exhibition, uploaded_file)
      @exhibition_medium.file.attach(blob)
    end

    if @exhibition_medium.save
      redirect_to admin_exhibition_exhibition_media_path(@exhibition), notice: "Media successfully uploaded"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_create
    uploaded_files = params[:files]

    # Debug logging
    Rails.logger.info "========== BULK UPLOAD DEBUG =========="
    Rails.logger.info "Files param: #{params[:files].inspect}"
    Rails.logger.info "Files class: #{params[:files].class}"
    Rails.logger.info "Files is array: #{params[:files].is_a?(Array)}"
    Rails.logger.info "======================================="

    # Handle case where no files were selected
    if uploaded_files.blank?
      redirect_to new_admin_exhibition_exhibition_medium_path(@exhibition),
                  alert: "Please select at least one file to upload"
      return
    end

    # Ensure uploaded_files is an array
    uploaded_files = Array(uploaded_files)

    success_count = 0
    error_count = 0

    uploaded_files.each do |file|
      next if file.blank? # Skip empty file inputs

      blob = ExhibitionMedium.create_blob_with_key(@exhibition, file)
      medium = @exhibition.exhibition_media.new(
        photographer: params[:photographer],
        position: @exhibition.exhibition_media.count + 1
      )
      medium.file.attach(blob)

      if medium.save
        success_count += 1
      else
        error_count += 1
      end
    end

    if success_count.zero?
      redirect_to new_admin_exhibition_exhibition_medium_path(@exhibition),
                  alert: "No files were uploaded. Please try again."
    elsif error_count.zero?
      redirect_to admin_exhibition_exhibition_media_path(@exhibition),
                  notice: "Successfully uploaded #{success_count} #{'file'.pluralize(success_count)}"
    else
      redirect_to admin_exhibition_exhibition_media_path(@exhibition),
                  alert: "Uploaded #{success_count} files, #{error_count} failed"
    end
  end

  def edit
  end

  def update
    uploaded_file = params[:exhibition_medium]&.delete(:file)

    if uploaded_file.present?
      blob = ExhibitionMedium.create_blob_with_key(@exhibition, uploaded_file)
      @exhibition_medium.file.attach(blob)
    end

    if @exhibition_medium.update(exhibition_medium_params)
      redirect_to admin_exhibition_exhibition_media_path(@exhibition), notice: "Media updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exhibition_medium.destroy
    redirect_to admin_exhibition_exhibition_media_path(@exhibition), notice: "Media deleted successfully"
  end

  private

  def set_exhibition
    # Handle both numeric IDs and slugs
    @exhibition = if params[:exhibition_id].to_i.to_s == params[:exhibition_id]
      Exhibition.find(params[:exhibition_id])
    else
      Exhibition.find_by!(slug: params[:exhibition_id])
    end
  end

  def set_exhibition_medium
    @exhibition_medium = @exhibition.exhibition_media.find(params[:id])
  end

  def exhibition_medium_params
    params.require(:exhibition_medium).permit(:file, :caption, :photographer, :position)
  end

  def require_admin
    redirect_to root_path, alert: "Access denied" unless Current.user&.admin?
  end
end
