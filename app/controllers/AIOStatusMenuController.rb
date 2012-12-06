require 'AIOObserver'

class AIOStatusMenuController
  include AIOObserver

  BOXES_MENU_SEPARATOR_TAG = 80435

  attr_accessor :menu

  def initialize
    @box_menu_nib = NSNib.alloc.initWithNibNamed 'BoxMenu', bundle: nil
  end

  def setup_menu
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu

    observe(AIOApp, 'boxes.content') { |v,c| boxes_content_did_change v,c }

    fetch_current_user
    fetch_boxes
  end

  def teardown_menu
    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil

    stop_observing AIOApp, 'boxes.content'
  end

  def open_action_io_website(sender)
    open_url AIOSettings.host + '/'
  end

  private
  def fetch_current_user
    AIOApp.jobs.add_new 'current_user.fetch' do
      AIOApp.current_user.fetch
    end
  end

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
      objects_ptr = Pointer.new :object
      if @box_menu_nib.instantiateNibWithOwner box, topLevelObjects: objects_ptr
        objects = objects_ptr[0]
        nib_menu = objects.find { |o| o.kind_of? NSMenu }
        menu_item = nib_menu.itemAtIndex 0
        menu_item.setRepresentedObject box
        nib_menu.removeAllItems

        insertion_index = @menu.indexOfItemWithTag BOXES_MENU_SEPARATOR_TAG
        @menu.insertItem menu_item, atIndex: insertion_index
      end
    end
  end

  def remove_box_menu_item(box)
    Dispatch::Queue.main.async do
      if menu_item = @menu.itemAtIndex(@menu.indexOfItemWithRepresentedObject box)
        menu_item.setRepresentedObject nil
        @menu.removeItem menu_item
      end
    end
  end
end
