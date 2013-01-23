class AIOSignInViewController < NSViewController
  attr_accessor :loading, :username, :password

  def init
    if super.initWithNibName 'SignInView', bundle: nil
      self.loading = false
      self
    end
  end

  def did_click_sign_in_button(sender)
    self.loading = true
    concurrent_queue do
      begin
        AIOApp.api.sign_in @username, @password
      rescue => e
        err_msg = e.message.lines.first.strip
        if err_msg.include? 'invalid_resource_owner'
          err_msg = 'The username or password you entered is incorrect.'
        elsif e.kind_of? AIOAPI::KeychainError
          err_msg = 'Could not access keychain. Is your keychain locked?'
        end
        Dispatch::Queue.main.async do
          NSBeginCriticalAlertSheet 'Error', 'Okay', nil, nil, self.view.window, nil, nil, nil, nil, "%@", err_msg
        end
      ensure
        self.loading = false
      end
    end
  end

  def did_click_go_back_button(sender)
    AIOApp.welcome_window_controller.show_welcome_view
  end

  def did_click_forgot_password_button(sender)
    open_url AIOSettings.host + AIO_FORGOT_PASSWORD_PATH
  end
end
