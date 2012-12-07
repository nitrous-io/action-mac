require 'AIOObserver'

class AIOStatusMenuController
  include AIOObserver

  BOXES_MENU_SEPARATOR_TAG = 80435

  attr_accessor :menu

  def initialize
    @box_controller_mapping = {} # box to box menu controller mapping
  end

  def setup_menu
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu

    observe(AIOApp, 'boxes.content') { |v,c| boxes_content_did_change v,c }

    AIOApp.jobs.add_new 'current_user.fetch' do
      AIOApp.current_user.fetch
      fetch_boxes
    end
  end

  def teardown_menu
    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil

    stop_observing AIOApp, 'boxes.content'
  end

  def open_action_io_website(sender)
    concurrent_queue do
      AIOApp.api.sign_in_to_actionio_web_app_and_open '/'
    end
  end

  private
  def fetch_boxes
    AIOApp.jobs.add_new 'boxes.fetch' do
      AIOApp.boxes.fetch
    end
  end

  def boxes_content_did_change(value, change)
    case change[NSKeyValueChangeKindKey]
      when NSKeyValueChangeInsertion
        change[NSKeyValueChangeNewKey].each do |added_box|
          add_box_menu_item added_box
        end
      when NSKeyValueChangeRemoval
        change[NSKeyValueChangeOldKey].each do |removed_box|
          remove_box_menu_item removed_box
        end
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
