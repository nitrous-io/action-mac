require 'AIOObserver'

class AIOStatusMenuController
  include AIOObserver

  BOXES_MENU_SEPARATOR_TAG = 80435

  attr_accessor :ssh_key_pair_window_controller
  attr_accessor :menu

  def initialize
    @box_controller_mapping = {} # box to box menu controller mapping
  end

  def finalize
    NSNotificationCenter.defaultCenter.removeObserver self
  end

  def setup_menu
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon-gray')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Nitrous.IO'
    @status_item.setMenu @menu

    observe(AIOApp, 'boxes.content') { |v,c| boxes_content_did_change v,c }
    observe(AIOApp, 'connected'    ) { |v,c| connected_did_change v,c }
  end

  def teardown_menu
    stop_observing AIOApp, 'boxes.content'
    stop_observing AIOApp, 'connected'

    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil
  end

  def did_click_open_action_io_website_menu_item(sender)
    Dispatch::Queue.main.async do
      AIOMixPanel.track 'Mac App Opened Website'
    end
    concurrent_queue do
      AIOApp.api.sign_in_to_actionio_web_app_and_open '/'
    end
  end

  def did_click_open_action_io_folder_menu_item(sender)
    Dispatch::Queue.main.async do
      AIOMixPanel.track 'Mac App Opened Folder'
    end
    folder_path = File.join Dir.home, FILE_SYNC_FOLDER_NAME
    folder_path_url = NSURL.fileURLWithPath folder_path, isDirectory: true
    NSWorkspace.sharedWorkspace.openURL folder_path_url
  end

  def did_click_preferences_menu_item(sender)
    Dispatch::Queue.main.async do
      AIOMixPanel.track 'Mac App Opened Preferences'
    end
    AIOApp.open_preferences_window
  end

  private
  def boxes_content_did_change(value, change)
    case change[NSKeyValueChangeKindKey]
      when NSKeyValueChangeInsertion
        add_new_items change
      when NSKeyValueChangeRemoval
        remove_old_items change
      when NSKeyValueChangeReplacement
        remove_old_items change
        add_new_items change
    end
  end

  def connected_did_change(connected, change)
    @status_item.setImage NSImage.imageNamed("status-item-icon#{'-gray' unless connected}")
  end

  def add_new_items(change)
    change[NSKeyValueChangeNewKey].each do |added_box|
      add_box_menu_item added_box
    end
  end

  def remove_old_items(change)
    change[NSKeyValueChangeOldKey].each do |removed_box|
      remove_box_menu_item removed_box
    end
  end

  def add_box_menu_item(box)
    Dispatch::Queue.main.async do
      box_menu_controller = AIOBoxMenuController.new box
      @box_menu_nib ||= NSNib.alloc.initWithNibNamed 'BoxMenu', bundle: nil
      if @box_menu_nib.instantiateNibWithOwner box_menu_controller, topLevelObjects: nil
        menu_item = box_menu_controller.menu_item
        menu_item.menu.removeAllItems
        insertion_index = @menu.indexOfItemWithTag BOXES_MENU_SEPARATOR_TAG
        @menu.insertItem menu_item, atIndex: insertion_index
        @box_controller_mapping[box] = box_menu_controller
      end
    end
  end

  def remove_box_menu_item(box)
    Dispatch::Queue.main.async do
      if box_menu_controller = @box_controller_mapping.delete(box)
        @menu.removeItem box_menu_controller.menu_item
      end
    end
  end
end
