class AIOSSHKeysPreferencesViewController < NSViewController
  attr_accessor :generating

  def init
    if super.initWithNibName 'SSHKeysPreferencesView', bundle: nil
      setTitle 'SSH Keys'
      self.generating = false
      did_click_reload_button nil
      self
    end
  end

  def did_click_reload_button(sender)
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
end
