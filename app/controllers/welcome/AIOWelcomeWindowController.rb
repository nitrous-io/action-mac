class AIOWelcomeWindowController < NSWindowController
  attr_reader :welcome_view_controller, :sign_in_view_controller, :sign_up_view_controller
  attr_accessor :closing_should_terminate_app

  def init
    if super.initWithWindowNibName 'WelcomeWindow'
      @welcome_view_controller = AIOWelcomeViewController.new
      @sign_in_view_controller = AIOSignInViewController.new
      @sign_up_view_controller = AIOSignUpViewController.new
      @closing_should_terminate_app = true
      show_welcome_view
      self
    end
  end

  def show_welcome_view
    window.setContentView @welcome_view_controller.view
  end

  def show_sign_in_view
    window.setContentView @sign_in_view_controller.view
  end

  def show_sign_up_view
    window.setContentView @sign_up_view_controller.view
  end

  def close
    @closing_should_terminate_app = false
    super
  end

  def windowWillClose(notification)
    NSApp.terminate(self) if @closing_should_terminate_app
  end
end
