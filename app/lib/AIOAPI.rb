require 'json'
require 'oauth2'

class AIOAPI
  SCOPES = 'public boxes public_keys user'
  attr_reader :client
  attr_accessor :token, :username

  def initialize
    options = { site: AIOSettings.host }

    # disable ssl cert checking for development
    options[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if AIOSettings.env == 'development'

    @client = OAuth2::Client.new AIOSettings.oauth_client_id, AIOSettings.oauth_client_secret, options
  end

  def obtain_access_token(username, password)
    self.username = username
    self.token = @client.password.get_token(username, password, parse: :json, scope: SCOPES)
  end
end
