class AIOWelcomeWindowController < NSWindowController
  attr_reader :welcome_view_controller, :sign_in_view_controller, :sign_up_view_controller

  def init
    if super.initWithWindowNibName 'WelcomeWindow'
      @welcome_view_controller = AIOWelcomeViewController.new
      @sign_in_view_controller = AIOSignInViewController.new
      @sign_up_view_controller = AIOSignUpViewController.new
      show_welcome_view
      self
    end
  end

  def show_welcome_view
    self.window.setContentView @welcome_view_controller.view
  end

  def show_sign_in_view
    self.window.setContentView @sign_in_view_controller.view
  end

  def show_sign_up_view
    self.window.setContentView @sign_up_view_controller.view
  end

  def windowWillClose(notification)
    NSApp.terminate self
  end
end
