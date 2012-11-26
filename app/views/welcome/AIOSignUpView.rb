class AIOSignUpView < NSView
  def viewDidMoveToWindow
    if window
      if sign_up_view_controller = NSApp.delegate.valueForKeyPath('welcome_window_controller.sign_up_view_controller')
        sign_up_view_controller.schedule_to_open_web_page
      end
    end
  end
end
