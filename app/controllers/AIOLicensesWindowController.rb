class AIOLicensesWindowController < NSWindowController
  attr_accessor :text_view

  def init
    if super.initWithWindowNibName 'LicensesWindow'
      self
    end
  end

  def windowDidLoad
    path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
    self.text_view.setString File.read("#{path}/LICENSE")
  end

  def show_window
    window.makeKeyAndOrderFront nil
    NSApp.activateIgnoringOtherApps true
  end
end
