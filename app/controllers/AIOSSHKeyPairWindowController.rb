class AIOSSHKeyPairWindowController < NSWindowController
  include AIOSSHKeyPairUI

  attr_accessor :generate_keypair_view, :register_keypair_view
  attr_accessor :generating, :registering

  def init
    if super.initWithWindowNibName 'SSHKeyPairWindow'
      self.generating = false
      self.registering = false
      self
    end
  end

  def generating_or_registering
    @generating || @registering
  end
  dependent_property :generating_or_registering, [:generating, :registering]

  def show_generate_keypair_window
    window # load nib
    show_window_with_view @generate_keypair_view
  end

  def show_register_keypair_window
    window # load nib
    show_window_with_view @register_keypair_view
  end

  def did_click_generate_button(sender)
    concurrent_queue { generate_key_pair true }
  end

  def did_click_register_button(sender)
    concurrent_queue { read_and_register_public_key }
  end

  def ssh_key_pair_did_register
    close
  end

  private
  def show_window_with_view(view)
    window = self.window
    window.setContentView view
    window.makeKeyAndOrderFront nil
    NSApp.activateIgnoringOtherApps true
  end

  def ignore_already_registered
    true
  end
end
