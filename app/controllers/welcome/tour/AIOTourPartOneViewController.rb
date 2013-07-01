class AIOTourPartOneViewController < NSViewController
  def init
    if super.initWithNibName 'TourPartOneView', bundle: nil
      self
    end
  end

  def did_click_skip_tour_button(sender)
    AIOApp.close_welcome_window
  end

  def did_click_continue_button(sender)
    AIOApp.welcome_window_controller.show_tour_part_two_view
  end
end
