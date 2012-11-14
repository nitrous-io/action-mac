class AIOSignInViewController < NSViewController
  def init
    if super.initWithNibName 'SignInView', bundle: nil
      self
    end
  end

  def did_click_sign_in_button(sender)
  end

  def did_click_go_back_button(sender)
    NSApp.delegate.welcome_window_controller.show_welcome_view
  end

  def did_click_forgot_password_button(sender)
  end
end