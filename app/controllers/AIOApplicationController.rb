class AIOApplicationController
  attr_accessor :window, :menu
  attr_reader :api, :welcome_window_controller, :status_item

  def applicationDidFinishLaunching(notification)
    @api = AIOAPI.new
    begin
      @api.read_access_token_from_keychain
    rescue AIOAPI::KeychainError => e
      NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
      NSApp.terminate self
    end

    if @api.token
      setup_status_item
    else
      show_welcome_window
    end
  end

  def show_welcome_window
    @welcome_window_controller = AIOWelcomeWindowController.new
    self.window = @welcome_window_controller.window
    window.makeKeyAndOrderFront nil
    window.orderFrontRegardless
  end

  def close_welcome_window
    @welcome_window_controller.close
    @welcome_window_controller = nil
  end

  def setup_status_item
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu
  end
end
