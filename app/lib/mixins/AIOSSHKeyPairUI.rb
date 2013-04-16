module AIOSSHKeyPairUI
  attr_accessor :generating, :registering

  protected
  def find_keys
    AIOApp.ssh_key_pair.find_keys
  end

  def generate_key_pair(register=false)
    self.generating = true
    begin
      AIOApp.ssh_key_pair.generate!
    rescue => e
      err_msg = e.message.strip
      show_error_message err_msg
    else
      read_and_register_public_key if register
    ensure
      self.generating = false
    end
  end

  def read_and_register_public_key(passphrase='')
    self.registering = true
    ssh_key_pair = AIOApp.ssh_key_pair
    begin
      ssh_key_pair.read_public_key passphrase
      AIOApp.public_keys.register ssh_key_pair.public_key
    rescue => e
      err_msg = case e
                when AIOSSHKeyPair::PassphraseRequiredError
                  prompt_user_for_password
                when AIOPublicKeyCollection::PublicKeyAlreadyRegisteredError
                  "Public key is already registered with Nitrous.IO." unless ignore_already_registered
                when AIOPublicKeyCollection::PublicKeyInvalidError
                  "Public key is invalid."
                when OpenSSL::PKey::PKeyError
                  "Incorrect passphrase or invalid SSH keypair."
                else
                  e.message.strip
                end
      show_error_message err_msg if err_msg
    ensure
      self.registering = false
      if e.nil? || e.kind_of?(AIOPublicKeyCollection::PublicKeyAlreadyRegisteredError)
        if respond_to? :ssh_key_pair_did_register
          ssh_key_pair_did_register
        end
      end
    end
  end

  def show_error_message(msg)
    Dispatch::Queue.main.async do
      NSBeginCriticalAlertSheet 'Error', 'OK', nil, nil, self.window, nil, nil, nil, nil, "%@", msg
    end
  end

  def prompt_user_for_password
    Dispatch::Queue.main.async do
      alert = NSAlert.alertWithMessageText 'Enter your passphrase for the SSH key.', defaultButton: 'OK', alternateButton: nil, otherButton: 'Cancel', informativeTextWithFormat: ''
      text_field = NSSecureTextField.alloc.initWithFrame [[0, 0], [295, 22]]
      alert.setAccessoryView text_field
      alert.beginSheetModalForWindow self.window, modalDelegate: self, didEndSelector: 'password_prompt_did_end:', contextInfo: nil
    end
  end

  def password_prompt_did_end(alert, return_code, context_info)
    if return_code == NSAlertDefaultReturn
      passphrase = alert.accessoryView.stringValue
      if passphrase.nil? || passphrase.empty?
        prompt_user_for_password
      else
        read_and_register_public_key passphrase
      end
    end
  end

  def ignore_already_registered
    false
  end
end
