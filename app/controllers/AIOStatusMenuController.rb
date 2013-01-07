require 'AIOObserver'

class AIOStatusMenuController
  include AIOObserver

  BOXES_MENU_SEPARATOR_TAG = 80435

  attr_accessor :ssh_key_pair_window_controller
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
    NSNotificationCenter.defaultCenter.addObserver self, selector: 'job_completed:', name: 'AIOJobCompletionNotification', object: nil

    fetch_current_user
  end

  def teardown_menu
    NSNotificationCenter.defaultCenter.removeObserver self, name: 'AIOJobCompletionNotification', object: nil
    stop_observing AIOApp, 'boxes.content'

    NSStatusBar.systemStatusBar.removeStatusItem @status_item
    @status_item = nil
  end

  def did_click_open_action_io_website_menu_item(sender)
    concurrent_queue do
      AIOApp.api.sign_in_to_actionio_web_app_and_open '/'
    end
  end

  def did_click_preferences_menu_item(sender)
    AIOApp.open_preferences_window
  end

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

  def fetch_public_keys
    AIOApp.jobs.add_new 'public_keys.fetch' do
      AIOApp.public_keys.fetch
    end
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

  def check_whether_public_key_is_registered
    ssh_key_pair = AIOApp.ssh_key_pair
    ssh_key_pair.find_keys

    if ssh_key_pair.private_key_path.nil?
      Dispatch::Queue.main.async do
        self.ssh_key_pair_window_controller = AIOSSHKeyPairWindowController.new
        @ssh_key_pair_window_controller.show_generate_keypair_window
      end
      return
    end
    if ssh_key_pair.public_key_path
      ssh_key_pair.read_public_key
      md5_fingerprint = ssh_key_pair.public_key_md5_fingerprint
      return if AIOApp.public_keys.models.find { |k| k.md5_fingerprint == md5_fingerprint }
    end
    Dispatch::Queue.main.async do
      self.ssh_key_pair_window_controller = AIOSSHKeyPairWindowController.new
      @ssh_key_pair_window_controller.show_register_keypair_window
    end
  end

  def job_completed(notification)
    job = notification.object
    return if job.cancelled

    case job.name
    when 'current_user.fetch'
      fetch_boxes
      fetch_public_keys
    when 'public_keys.fetch'
      concurrent_queue do
        check_whether_public_key_is_registered
      end
    end
  end
end
