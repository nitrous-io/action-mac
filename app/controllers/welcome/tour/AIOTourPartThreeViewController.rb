class AIOTourPartThreeViewController < NSViewController
  def init
    if super.initWithNibName 'TourPartThreeView', bundle: nil
      self
    end
  end

  def did_click_go_back_button(sender)
    AIOApp.welcome_window_controller.show_tour_part_two_view
  end

  def did_click_finish_button(sender)
    AIOApp.close_welcome_window
  end
end
