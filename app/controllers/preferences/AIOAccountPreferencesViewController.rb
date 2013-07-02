class AIOAccountPreferencesViewController < NSViewController
  def init
    if super.initWithNibName 'AccountPreferencesView', bundle: nil
      setTitle 'Account'
      self
    end
  end

  def did_click_sign_out_button(sender)
    AIOApp.sign_out
  end
end
