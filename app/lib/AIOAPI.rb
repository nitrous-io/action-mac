framework 'Security'
require 'cgi'

class AIOAPI
  SCOPES = 'public boxes public_keys user push web'
  API_PATH_PREFIX = '/api/v0'
  USERNAME_KEY = 'username'

  class KeychainError < StandardError; end

  attr_reader :oauth
  attr_accessor :username, :signed_in

  def initialize
    @signed_in = false

    @oauth = AIOOAuth.alloc.initWithHost(AIOSettings.host, clientID: AIOSettings.oauth_client_id, clientSecret: AIOSettings.oauth_client_secret)
    @oauth.setUserAgent(AIOSettings.user_agent)
    if %w(development test).include? AIOSettings.env
      @oauth.setVerifySSL 0
    end
  end

  def request(verb, path, options={}, &block)
    return unless @oauth.accessToken
    AIOLog "request: #{verb} #{path}"
    @oauth.request(verb.to_s, path: path, options: options, success: -> (response) {
      AIOLog "success: #{response.statusCode} #{path} : #{response.json}"
      block.call nil, response if block
    }, failure: -> (err, response) {
      AIOLog "fail: #{response.statusCode} #{path} : #{err} #{response.json}"
      block.call err, response if block
    })
  end

  def sign_in(username=nil, password=nil, &block)
    @oauth.obtainAccessTokenWithUsername(username, password: password, success: -> (access_token, response) {
      self.username = username
      begin
        write_access_token_to_keychain
      rescue => err
        self.signed_in = false
        block.call err, response if block
      else
        self.signed_in = true
        block.call nil, response if block
      end
    }, failure: -> (err, response) {
      self.signed_in = false
      block.call err, response if block
    })
  end

  def sign_in_with_keychain
    read_access_token_from_keychain
    self.signed_in = !@oauth.accessToken.nil?
  end

  def sign_out
    self.signed_in = false
    remove_access_token_from_keychain
    @oauth.accessToken = nil
  end

  def sign_in_to_actionio_web_app_and_open(url='/')
    request(:get, '/user/sign_in_token') do |err, response|
      if err
        return
      elsif token = response.json['sign_in_token']
        Dispatch::Queue.main.async do
          open_url "#{AIOSettings.host}/users/sign_in_with_token?sign_in_token=#{CGI.escape token}&redirect_to=#{CGI.escape url}"
        end
      end
    end
  end

  private
  def write_access_token_to_keychain
    if token = @oauth.accessToken
      AIOStore.write USERNAME_KEY, @username

      error_ptr = Pointer.new :object
      SSKeychain.setPassword token, forService: AIOSettings.keychain_service_name, account: @username, error: error_ptr
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
        @oauth.accessToken = token_string
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
