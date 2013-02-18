class AIOGeneralPreferencesViewController < NSViewController
  include AIOObserver

  attr_accessor :version, :debug_enabled

  def init
    if super.initWithNibName 'GeneralPreferencesView', bundle: nil
      setTitle 'General'
      self.version = AIOSettings.version
      self.debug_enabled = AIOStore.read 'debug'
      observe(self, 'debug_enabled') { |v,c| debug_enabled_did_change v,c }
      self
    end
  end

  def finalize
    stop_observing self, 'debug_enabled'
  end

  def did_click_licenses_button(sender)
    @licences_window_controller ||= AIOLicensesWindowController.new
    @licences_window_controller.show_window
  end

  private
  def debug_enabled_did_change(value, change)
    AIOStore.write 'debug', value
  end
end
