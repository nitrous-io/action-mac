require 'SpecHelper'

class SpecAppDelegate
  def applicationDidFinishLaunching(notification)
    Bacon.extend Bacon::TestUnitOutput
    Bacon.run
  end
end
