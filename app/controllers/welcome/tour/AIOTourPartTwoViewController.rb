class AIOTourPartTwoViewController < NSViewController
  def init
    if super.initWithNibName 'TourPartTwoView', bundle: nil
      self
    end
  end

  def did_click_skip_tour_button(sender)
    AIOApp.close_welcome_window
  end

  def did_click_go_back_button(sender)
    AIOApp.welcome_window_controller.show_tour_part_one_view
  end

  def did_click_continue_button(sender)
    AIOApp.welcome_window_controller.show_tour_part_three_view
  end
end
