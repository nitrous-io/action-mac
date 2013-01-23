class AIOBoxFileSync
  include AIOObserver

  attr_accessor :box
  attr_accessor :file_sync_task
  attr_accessor :enabled

  def initialize(box)
    self.enabled = false
    self.box = box
    load_data
    observe(self, 'enabled', initial: true) { |v,c| enabled_did_change v,c }
    self.file_sync_task = AIOFileSyncTask.new self
    start_or_kill_file_sync_task
  end

  private
  def load_data
    self.enabled = AIOApp.store.read(file_sync_enabled_key) || false
  end

  def enabled_did_change(value, change)
    AIOApp.store.write file_sync_enabled_key, value
    start_or_kill_file_sync_task
  end

  def start_or_kill_file_sync_task
    if @file_sync_task
      @enabled ? @file_sync_task.start_monitoring : @file_sync_task.stop_monitoring
    end
  end

  def file_sync_enabled_key
    "user:#{AIOApp.current_user.id}:box:#{@box.id}:file_sync_enabled" if @box
  end
end
