class AIOGeneralPreferencesViewController < NSViewController
  attr_accessor :version

  def init
    if super.initWithNibName 'GeneralPreferencesView', bundle: nil
      setTitle 'General'
      self.version = AIOSettings.version
      self
    end
  end
end
