class AIOSSHKeysPreferencesViewController < NSViewController
  attr_accessor :generating, :registering

  def init
    if super.initWithNibName 'SSHKeysPreferencesView', bundle: nil
      setTitle 'SSH Keys'
      self.generating = false
      did_click_rescan_button nil
      self
    end
  end

  def did_click_rescan_button(sender)
    concurrent_queue do
      AIOApp.ssh_key_pair.find_keys
    end
  end

  def did_click_generate_button(sender)
    self.generating = true
    concurrent_queue do
      AIOApp.ssh_key_pair.generate!
      self.generating = false
    end
  end

  def did_click_register_public_key_to_action_io_button(sender)
    read_and_register_public_key
  end

  private
  def read_and_register_public_key(passphrase='')
    self.registering = true
    concurrent_queue do
      ssh_key_pair = AIOApp.ssh_key_pair
      begin
        ssh_key_pair.read_public_key passphrase
        AIOApp.public_keys.register ssh_key_pair.public_key
      rescue => e
        err_msg = case e
                  when AIOSSHKeyPair::PassphraseRequiredError
                    prompt_user_for_password
                  when AIOPublicKeyCollection::PublicKeyAlreadyRegisteredError
                    "Public key is already registered with Action.IO."
                  when AIOPublicKeyCollection::PublicKeyInvalidError
                    "Public key is invalid."
                  when OpenSSL::PKey::PKeyError
                    "Incorrect passphrase or invalid SSH keypair."
                  else
                    e.message.strip
                  end
        Dispatch::Queue.main.async do
          NSBeginCriticalAlertSheet 'Error', 'OK', nil, nil, self.view.window, nil, nil, nil, nil, "%@", err_msg
        end
      ensure
        self.registering = false
      end
    end
  end

  def prompt_user_for_password
    Dispatch::Queue.main.async do
      alert = NSAlert.alertWithMessageText nil, defaultButton: 'OK', alternateButton: nil, otherButton: 'Cancel', informativeTextWithFormat: 'Enter your passphrase for the SSH key.'
      text_field = NSSecureTextField.alloc.initWithFrame [[0, 0], [295, 22]]
      alert.setAccessoryView text_field
      alert.beginSheetModalForWindow self.view.window, modalDelegate: self, didEndSelector: :'alertDidEnd:returnCode:contextInfo:', contextInfo: nil
    end
  end

  def alertDidEnd(alert, returnCode: return_code, contextInfo: context_info)
    if return_code == NSAlertDefaultReturn
      passphrase = alert.accessoryView.stringValue
      if passphrase.nil? || passphrase.empty?
        prompt_user_for_password
      else
        read_and_register_public_key passphrase
      end
    end
  end
end
