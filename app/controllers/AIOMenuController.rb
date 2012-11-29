class AIOMenuController
  attr_accessor :menu
  attr_reader :status_item

  def setup_menu
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu
  end

  def teardown_menu
    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil
  end

  def open_action_io_website(sender)
    NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(AIOSettings.host + '/')
  end
end
