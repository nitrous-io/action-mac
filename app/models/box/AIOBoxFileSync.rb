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
    observe(@box, 'state',   initial: true) { |v,c| box_state_did_change v,c }
    self.file_sync_task = AIOFileSyncTask.new self
    start_or_kill_file_sync_task
  end

  def finalize
    stop_observing self, 'enabled'
    stop_observing @box, 'state'
  end

  private
  def load_data
    self.enabled = AIOStore.read(file_sync_enabled_key) || false
  end

  def enabled_did_change(value, change)
    AIOStore.write file_sync_enabled_key, value
    start_or_kill_file_sync_task
  end

  def box_state_did_change(value, change)
    start_or_kill_file_sync_task
  end

  def start_or_kill_file_sync_task
    if @file_sync_task
      if @enabled && @box.state == AIOBox::STATE_RUNNING
        @file_sync_task.start_monitoring
      else
        @file_sync_task.stop_monitoring
      end
    end
  end

  def file_sync_enabled_key
    "user:#{AIOApp.current_user.id}:box:#{@box.id}:file_sync_enabled" if @box
  end
end
