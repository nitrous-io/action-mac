class AIOApplicationController
  attr_accessor :window, :menu_controller
  attr_reader :api, :welcome_window_controller

  def applicationDidFinishLaunching(notification)
    @api = AIOAPI.new
    addObserver self, forKeyPath: 'api.token', options: 0, context: nil

    begin
      @api.read_access_token_from_keychain
    rescue AIOAPI::KeychainError => e
      show_keychain_error
    end

    show_welcome_window unless @api.token
  end

  def finalize
    removeObserver self, forKeyPath: 'api.token'
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

  def show_menu_and_close_welcome_window
    close_welcome_window if @welcome_window_controller
    @menu_controller.setup_menu unless @menu_controller.status_item
  end

  def show_welcome_window_and_remove_menu
    @menu_controller.teardown_menu if @menu_controller.status_item
    show_welcome_window unless @welcome_window_controller
  end

  # observer
  def observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    val = object.valueForKeyPath keyPath
    if object == self && keyPath == 'api.token'
      if val.nil?
        begin
          @api.remove_access_token_from_keychain
        rescue AIOAPI::KeychainError => e
          show_keychain_error
        ensure
          show_welcome_window_and_remove_menu
        end
      else
        show_menu_and_close_welcome_window
      end
    end
  end

  private
  def show_keychain_error
    NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
    NSApp.terminate self
  end
end
