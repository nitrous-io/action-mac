class AIOAppDelegate
  attr_accessor :controller

  def applicationDidFinishLaunching(notification)
    self.controller = AIOAppController.new
  end
end
