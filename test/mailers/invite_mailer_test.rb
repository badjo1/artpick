require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "send_invite" do
    invite_link = invite_links(:one)
    email = "test@example.com"

    mail = InviteMailer.send_invite(email, invite_link)

    assert_equal "Je bent uitgenodigd om te stemmen op kunstwerken", mail.subject
    assert_equal [email], mail.to
    assert_match invite_link.token, mail.body.encoded
  end
end
