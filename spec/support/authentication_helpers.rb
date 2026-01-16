module AuthenticationHelpers
  def auth_headers
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(
      ENV.fetch('ADMIN_USERNAME', 'admin'),
      ENV.fetch('ADMIN_PASSWORD', 'password')
    )
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  def auth_cookies
    { authed: 'authenticated' }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
