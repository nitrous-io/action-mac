class AIOWelcomeViewController < NSViewController
  attr_accessor :user_has_account

  def init
    if super.initWithNibName 'WelcomeView', bundle: nil
      @user_has_account = false
      self
    end
  end

  def did_click_continue_button(sender)
    welcome_window_controller = NSApp.delegate.welcome_window_controller
    if @user_has_account
      welcome_window_controller.show_sign_in_view
    else
      welcome_window_controller.show_sign_up_view
    end
  end
end