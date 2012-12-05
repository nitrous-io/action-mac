require 'AIOObserver'

class AIOMenuController
  include AIOObserver

  BOXES_MENU_SEPARATOR_TAG = 80435

  attr_accessor :menu
  attr_reader :status_item

  def awakeFromNib
    @box_menu_nib = NSNib.alloc.initWithNibNamed 'BoxMenu', bundle: nil
    @box_menu_item_mapping = {}
  end

  def finalize
    @box_menu_item_mapping = nil
  end

  def setup_menu
    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
    @status_item.setHighlightMode true
    @status_item.setImage NSImage.imageNamed('status-item-icon')
    @status_item.setAlternateImage NSImage.imageNamed('status-item-icon-highlighted')
    @status_item.setToolTip 'Action.IO'
    @status_item.setMenu @menu

    app_controller = NSApp.delegate
    observe(app_controller, 'boxes.content') { |v,c| boxes_content_did_change v,c }

    fetch_current_user
    fetch_boxes
  end

  def teardown_menu
    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil

    app_controller = NSApp.delegate
    stop_observing app_controller, 'boxes.content'
  end

  def open_action_io_website(sender)
    open_url AIOSettings.host + '/'
  end

  private
  def fetch_current_user
    app_controller = NSApp.delegate
    current_user_fetch_job = AIOJob.new 'current_user.fetch' do
      app_controller.current_user.fetch
    end
    app_controller.jobs.add current_user_fetch_job
  end

  def fetch_boxes
    app_controller = NSApp.delegate
    boxes_fetch_job = AIOJob.new 'boxes.fetch' do
      app_controller.boxes.fetch
    end
    app_controller.jobs.add boxes_fetch_job
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
        box_menu = objects.find { |o| o.kind_of? NSMenu }
        menu_item = box_menu.itemAtIndex 0
        box_menu.removeAllItems

        insertion_index = @menu.indexOfItemWithTag BOXES_MENU_SEPARATOR_TAG
        @menu.insertItem menu_item, atIndex: insertion_index
        @box_menu_item_mapping[box] = menu_item
      end
    end
  end

  def remove_box_menu_item(box)
    Dispatch::Queue.main.async do
      if menu_item = @box_menu_item_mapping.delete(box)
        @menu.removeItem menu_item
      end
    end
  end
end
