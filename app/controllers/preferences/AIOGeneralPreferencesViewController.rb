class AIOGeneralPreferencesViewController < NSViewController
  include AIOObserver

  attr_accessor :version, :debug_enabled, :add_as_login_item

  def init
    if super.initWithNibName 'GeneralPreferencesView', bundle: nil
      setTitle 'General'
      self.version = AIOSettings.version
      self.debug_enabled = AIOStore.read 'debug'
      self.add_as_login_item = AIOStore.read 'add_as_login_item'
      observe(self, 'debug_enabled') { |v,c| debug_enabled_did_change v,c }
      observe(self, 'add_as_login_item') { |v,c| add_as_login_item_did_change v,c }
      self
    end
  end

  def finalize
    stop_observing self, 'debug_enabled'
    stop_observing self, 'add_as_login_item'
  end

  def did_click_licenses_button(sender)
    @licences_window_controller ||= AIOLicensesWindowController.new
    @licences_window_controller.show_window
  end

  private
  def debug_enabled_did_change(value, change)
    AIOStore.write 'debug', value
  end

  def add_as_login_item_did_change(value, change)
    AIOStore.write 'add_as_login_item', value
    if value
      AIOLoginItem.addAppToLoginItems
    else
      AIOLoginItem.removeAppFromLoginItems
    end
  end
end
