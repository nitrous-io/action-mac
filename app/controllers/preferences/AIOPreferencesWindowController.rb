class AIOPreferencesWindowController < NSWindowController
  attr_accessor :toolbar, :empty_view
  attr_accessor :general_preferences_view_controller,
                :account_preferences_view_controller,
                :ssh_keys_preferences_view_controller,

  def init
    if super.initWithWindowNibName 'PreferencesWindow'
      self
    end
  end

  def windowDidLoad
    self.toolbar.setSelectedItemIdentifier 'GeneralPreferences'
    show_general_preferences_view nil
  end

  def show_window
    window.makeKeyAndOrderFront nil
    NSApp.activateIgnoringOtherApps true
  end

  def show_general_preferences_view(sender)
    show_view_controller(
      self.general_preferences_view_controller ||= AIOGeneralPreferencesViewController.new
    )
  end

  def show_account_preferences_view(sender)
    show_view_controller(
      self.account_preferences_view_controller ||= AIOAccountPreferencesViewController.new
    )
  end

  def show_ssh_keys_preferences_view(sender)
    show_view_controller(
      self.ssh_keys_preferences_view_controller ||= AIOSSHKeysPreferencesViewController.new
    )
  end

  private
  def show_view_controller(view_controller)
    window.setTitle view_controller.title
    old_frame = window.frame
    new_frame = window.frameRectForContentRect [NSZeroPoint, view_controller.view.frame.size]
    new_frame.origin = [NSMinX(old_frame), NSMaxY(old_frame) - NSHeight(new_frame)]
    old_view = window.contentView
    window.setContentView @empty_view
    window.setFrame new_frame, display: true, animate: old_view != @empty_view
    window.setContentView view_controller.view
  end
end
