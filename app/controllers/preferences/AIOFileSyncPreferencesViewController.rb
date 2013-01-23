class AIOFileSyncPreferencesViewController < NSViewController
  def init
    if super.initWithNibName 'FileSyncPreferencesView', bundle: nil
      setTitle 'File Synchronization'
      self
    end
  end
end
