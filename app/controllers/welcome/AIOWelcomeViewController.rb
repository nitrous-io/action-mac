class AIOWelcomeViewController < NSViewController
  attr_accessor :user_has_account

  def init
    if super.initWithNibName 'WelcomeView', bundle: nil
      self.user_has_account = false
      self
    end
  end

  def did_click_continue_button(sender)
    if @user_has_account
      AIOApp.welcome_window_controller.show_sign_in_view
    else
      AIOApp.welcome_window_controller.show_sign_up_view
    end
  end
end
