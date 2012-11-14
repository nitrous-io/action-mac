class AIOApplicationController
  attr_accessor :window, :menu
  attr_reader :welcome_window_controller, :status_item

  def applicationDidFinishLaunching(notification)
    show_welcome_window
    #setup_status_item
  end

  def show_welcome_window
    @welcome_window_controller = AIOWelcomeWindowController.new
    window = @welcome_window_controller.window
    window.makeKeyAndOrderFront nil
  end

  def setup_status_item
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon.png')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted.png')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu
  end
end
