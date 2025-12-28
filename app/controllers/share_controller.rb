class ShareController < ApplicationController
  allow_unauthenticated_access

  def email
    email_address = params[:email]

    if email_address.blank?
      redirect_to results_path, alert: "E-mailadres is verplicht"
      return
    end

    # Generate a new invite link for this email
    invite_link = InviteLink.create!(name: "Email: #{email_address}")

    # Send the email
    InviteMailer.send_invite(email_address, invite_link).deliver_later

    redirect_to results_path, notice: "Uitnodiging verstuurd naar #{email_address}"
  end
end
