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
    AIOApp.api.sign_in(@username, @password, -> (err) {
      if err
        err_msg = if err.kind_of? NSError
          m = err.localizedDescription
          m == 'Authentication needed' ? 'The username or password you entered is incorrect.' : m
        elsif err.kind_of? AIOAPI::KeychainError
          'Could not access keychain. Is your keychain locked?'
        else
          err.description
        end
        NSBeginCriticalAlertSheet 'Error', 'Okay', nil, nil, self.view.window, nil, nil, nil, nil, "%@", err_msg
      else
        AIOApp.welcome_window_controller.show_tour_part_one_view
      end
      self.loading = false
    })
  end

  def did_click_go_back_button(sender)
    AIOApp.welcome_window_controller.show_welcome_view
  end

  def did_click_forgot_password_button(sender)
    open_url AIOSettings.host + AIO_FORGOT_PASSWORD_PATH
  end
end
