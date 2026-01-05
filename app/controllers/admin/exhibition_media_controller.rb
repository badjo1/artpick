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
    @exhibition_medium = @exhibition.exhibition_media.new(exhibition_medium_params)

    if @exhibition_medium.save
      redirect_to admin_exhibition_exhibition_media_path(@exhibition), notice: "Media successfully uploaded"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_create
    uploaded_files = params[:files] || []
    success_count = 0
    error_count = 0

    uploaded_files.each do |file|
      medium = @exhibition.exhibition_media.new(
        file: file,
        photographer: params[:photographer],
        position: @exhibition.exhibition_media.count + 1
      )

      if medium.save
        success_count += 1
      else
        error_count += 1
      end
    end

    if error_count.zero?
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
    @exhibition = Exhibition.find(params[:exhibition_id])
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
