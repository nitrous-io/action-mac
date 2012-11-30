framework 'Security'
require_relative 'AIOAPI'

class AIOAPI
  class KeychainError < StandardError; end

  def write_access_token_to_keychain
    if token
      defaults = NSUserDefaults.standardUserDefaults
      defaults.setObject username, forKey: KAIOUsernameKey

      error_ptr = Pointer.new :object
      SSKeychain.setPassword token.token, forService: AIOSettings.keychain_service_name, account: username, error: error_ptr
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end

      defaults.synchronize
    end
  end

  def read_access_token_from_keychain
    service = AIOSettings.keychain_service_name
    if account = NSUserDefaults.standardUserDefaults.stringForKey(KAIOUsernameKey)
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
    if account = NSUserDefaults.standardUserDefaults.stringForKey(KAIOUsernameKey)
      error_ptr = Pointer.new :object
      SSKeychain.deletePasswordForService(service, account: account, error: error_ptr)
      if error = error_ptr[0]
        raise KeychainError, error.localizedDescription
      end
    end
  end
end
