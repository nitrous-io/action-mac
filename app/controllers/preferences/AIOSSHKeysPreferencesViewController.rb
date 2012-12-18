class AIOSSHKeysPreferencesViewController < NSViewController
  include AIOSSHKeyPairUI

  def init
    if super.initWithNibName 'SSHKeysPreferencesView', bundle: nil
      setTitle 'SSH Keys'
      self.generating = false
      self.registering = false
      concurrent_queue { find_keys }
      self
    end
  end

  def did_click_rescan_button(sender)
    concurrent_queue { find_keys }
  end

  def did_click_generate_button(sender)
    concurrent_queue { generate_key_pair }
  end

  def did_click_register_public_key_to_action_io_button(sender)
    concurrent_queue { read_and_register_public_key }
  end
end
