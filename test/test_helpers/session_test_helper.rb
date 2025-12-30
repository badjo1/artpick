module SessionTestHelper
  def sign_in_as(user)
    session = user.sessions.create!
    Current.session = session

    # Set the signed cookie for integration tests
    verifier = Rails.application.message_verifier('signed cookie')
    cookies['session_id'] = verifier.generate(session.id)
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete('session_id')
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
