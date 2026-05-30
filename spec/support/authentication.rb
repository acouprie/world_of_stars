module AuthenticationHelper
  # Logs in the user via the sessions endpoint.
  # A preceding DELETE request triggers require_authentication, which stores a
  # return_to URL in the session — this prevents the subsequent POST from falling
  # back to root_url (which may not be defined yet).
  def sign_in(user, password: "Password1!")
    delete session_path
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
