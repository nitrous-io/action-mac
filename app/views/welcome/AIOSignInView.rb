class AIOSignInView < NSView
  attr_accessor :username_field

  def viewDidMoveToWindow
    if window
      @username_field.becomeFirstResponder
    end
  end
end
