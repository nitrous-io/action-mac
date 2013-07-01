class AIOWelcomeWindowController < NSWindowController
  attr_accessor :welcome_view_controller, :sign_in_view_controller, :sign_up_view_controller,
                :tour_part_one_view_controller, :tour_part_two_view_controller, :tour_part_three_view_controller

  def init
    if super.initWithWindowNibName 'WelcomeWindow'
      self.welcome_view_controller = AIOWelcomeViewController.new
      self.sign_in_view_controller = AIOSignInViewController.new
      self.sign_up_view_controller = AIOSignUpViewController.new
      self.tour_part_one_view_controller = AIOTourPartOneViewController.new
      self.tour_part_two_view_controller = AIOTourPartTwoViewController.new
      self.tour_part_three_view_controller = AIOTourPartThreeViewController.new
      @closing_should_terminate_app = true
      show_welcome_view
      self
    end
  end

  def show_window
    window.makeKeyAndOrderFront nil
    NSApp.activateIgnoringOtherApps true
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

  def show_tour_part_one_view
    window.setContentView @tour_part_one_view_controller.view
  end

  def show_tour_part_two_view
    window.setContentView @tour_part_two_view_controller.view
  end

  def show_tour_part_three_view
    window.setContentView @tour_part_three_view_controller.view
  end

  def close
    @closing_should_terminate_app = false
    super
  end

  def windowWillClose(notification)
    NSApp.terminate(self) if @closing_should_terminate_app
  end
end
