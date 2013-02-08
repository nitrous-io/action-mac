framework 'Security'
require 'oauth2'
require 'cgi'

class AIOAPI
  SCOPES = 'public boxes public_keys user push web'
  API_PATH_PREFIX = '/api/v0'
  USERNAME_KEY = 'username'

  class KeychainError < StandardError; end

  attr_reader :client
  attr_accessor :token, :username
  attr_accessor :signed_in

  def initialize
    options = { site: AIOSettings.host }
    # disable ssl cert checking for development
    options[:ssl] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if AIOSettings.env == 'development'
    @client = OAuth2::Client.new AIOSettings.oauth_client_id, AIOSettings.oauth_client_secret, options
    @signed_in = false
  end

  def obtain_access_token(username, password)
    self.username = username
    self.token = @client.password.get_token(username, password, parse: :json, scope: SCOPES)
  end

  def request(verb, path, options={})
    return unless @token
    response = @token.request verb.to_sym, "#{API_PATH_PREFIX}#{path}", { parse: :json }.merge(options)
  rescue OAuth2::Error => e
    response = e.response
    if response.status == 401 # token is invalid. destroy it.
      self.token = nil
    else
      raise e
    end
  rescue => e
    raise e
  end

  def obtain_sign_in_token
    if response = request(:get, '/user/sign_in_token')
      response.parsed['sign_in_token']
    end
  end

  def sign_in(username=nil, password=nil)
    if username && password
      obtain_access_token username, password
      write_access_token_to_keychain
    else
      read_access_token_from_keychain
    end
    self.signed_in = !self.token.nil?
  end

  def sign_out
    remove_access_token_from_keychain
    self.signed_in = false
  end

  def sign_in_to_actionio_web_app_and_open(url='/')
    if token = obtain_sign_in_token
      Dispatch::Queue.main.async do
        open_url "#{AIOSettings.host}/users/sign_in_with_token?sign_in_token=#{CGI.escape token}&redirect_to=#{CGI.escape url}"
      end
    end
  end

  private
  def write_access_token_to_keychain
    if token
      AIOStore.write USERNAME_KEY, @username

      error_ptr = Pointer.new :object
      SSKeychain.setPassword token.token, forService: AIOSettings.keychain_service_name, account: @username, error: error_ptr
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end
    end
  end

  def read_access_token_from_keychain
    service = AIOSettings.keychain_service_name
    if account = AIOStore.read(USERNAME_KEY)
      error_ptr = Pointer.new :object
      error = nil
      if token_string = SSKeychain.passwordForService(service, account: account, error: error_ptr)
        self.username = account
        self.token = OAuth2::AccessToken.new @client, token_string
      end
      error = error_ptr[0]
      if error && error.code != ErrSecItemNotFound
        raise KeychainError, error.localizedDescription
      end
    end
  end

  def remove_access_token_from_keychain
    service = AIOSettings.keychain_service_name
    if account = AIOStore.read(USERNAME_KEY)
      error_ptr = Pointer.new :object
      SSKeychain.deletePasswordForService(service, account: account, error: error_ptr)
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end
    end
  end
end
