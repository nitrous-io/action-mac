class AIOSignUpViewController < NSViewController
  def init
    if super.initWithNibName 'SignUpView', bundle: nil
      self
    end
  end

  def schedule_to_open_web_page
    @timer = NSTimer.scheduledTimerWithTimeInterval 2.0, target: self, selector: :open_web_page, userInfo: nil, repeats: false
  end

  def open_web_page
    open_url AIOSettings.host + AIO_SIGN_UP_PATH
    @timer = nil
  end

  def did_click_go_back_button(sender)
    @timer.invalidate if @timer
    AIOApp.welcome_window_controller.show_welcome_view
  end

  def did_click_reopen_page_button(sender)
    open_web_page
  end
end
