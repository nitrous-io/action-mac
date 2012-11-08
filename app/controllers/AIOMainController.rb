class AIOMainController
  attr_accessor :status_item, :menu

  def awakeFromNib
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon.png')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted.png')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu
  end
end
