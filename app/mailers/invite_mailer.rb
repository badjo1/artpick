class InviteMailer < ApplicationMailer
  def send_invite(email_address, invite_link)
    @invite_link = invite_link
    @invite_url = invite_url(token: invite_link.token)

    mail(
      to: email_address,
      subject: "Je bent uitgenodigd om te stemmen op kunstwerken"
    )
  end
end
