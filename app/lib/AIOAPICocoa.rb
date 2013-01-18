framework 'Security'
require 'AIOAPI'
require 'cgi'

class AIOAPICocoa < AIOAPI
  UsernameKey = 'username'

  class KeychainError < StandardError; end

  attr_accessor :signed_in

  def initialize
    super
    @signed_in = false
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
      AIOApp.store.write UsernameKey, @username

      error_ptr = Pointer.new :object
      SSKeychain.setPassword token.token, forService: AIOSettings.keychain_service_name, account: @username, error: error_ptr
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end
    end
  end

  def read_access_token_from_keychain
    service = AIOSettings.keychain_service_name
    if account = AIOApp.store.read(UsernameKey)
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
    if account = AIOApp.store.read(UsernameKey)
      error_ptr = Pointer.new :object
      SSKeychain.deletePasswordForService(service, account: account, error: error_ptr)
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end
    end
  end
end
