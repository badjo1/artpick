class Admin::ImagesController < ApplicationController
  include Authentication
  before_action :require_authentication
  before_action :set_image, only: [:edit, :update, :destroy]

  def index
    @images = Image.ranked.with_attached_file
  end

  def new
    @image = Image.new
  end

  def create
    @image = Image.new(image_params)

    if @image.save
      redirect_to admin_images_path, notice: "Afbeelding succesvol toegevoegd"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_new
    # Show bulk upload form
  end

  def bulk_create
    # Get uploaded files - Rails wraps them in an array
    uploaded_files = params[:files]

    # Handle case where files is nil or not an array
    if uploaded_files.blank?
      redirect_to bulk_new_admin_images_path, alert: "Geen bestanden geselecteerd"
      return
    end

    # Convert to array if it's a single file
    uploaded_files = [uploaded_files] unless uploaded_files.is_a?(Array)

    success_count = 0
    errors = []

    uploaded_files.each_with_index do |file, index|
      # Skip if file is empty or not a proper upload
      next if file.blank? || !file.respond_to?(:original_filename)

      # Generate a title from filename
      title = File.basename(file.original_filename, ".*").gsub(/[_-]/, " ").titleize

      image = Image.new(title: title)
      image.file.attach(file)

      if image.save
        success_count += 1
      else
        errors << "#{file.original_filename}: #{image.errors.full_messages.join(', ')}"
      end
    end

    if errors.empty? && success_count > 0
      redirect_to admin_images_path, notice: "#{success_count} afbeelding(en) succesvol geüpload"
    elsif success_count > 0
      flash[:alert] = "#{success_count} afbeelding(en) geüpload. Fouten: #{errors.join('; ')}"
      redirect_to bulk_new_admin_images_path
    else
      redirect_to bulk_new_admin_images_path, alert: "Fout bij uploaden: #{errors.join('; ')}"
    end
  end

  def edit
  end

  def update
    if @image.update(image_params)
      redirect_to admin_images_path, notice: "Afbeelding succesvol bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @image.destroy
    redirect_to admin_images_path, notice: "Afbeelding succesvol verwijderd"
  end

  private

  def set_image
    @image = Image.find(params[:id])
  end

  def image_params
    params.require(:image).permit(:title, :file)
  end
end
