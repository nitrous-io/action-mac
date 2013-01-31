class AIOAppDelegate
  attr_accessor :controller

  def applicationDidFinishLaunching(notification)
    self.controller = AIOAppController.new
  end

  def applicationWillTerminate(notification)
    @controller.application_will_terminate(notification) if @controller
  end
end
