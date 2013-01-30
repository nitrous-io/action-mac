require 'AIOConstants'
require 'AIOTask'
require 'fileutils'
require 'rb-fsevent'

system 'killall -9 actionio-unison'

class AIOFileSyncTask < AIOTask
  class NotSupportedError < StandardError; end

  IGNORE_LIST = 'Name {.git,.svn,.hg,CVS,.DS_Store,.AppleDouble,.LSOverride,.Spotlight-V100,.Trashes}'
  STATE_IDLE = 'idle'
  STATE_MONITORING = 'monitoring'
  STATE_SYNCING = 'syncing'
  STATE_ERROR = 'error'

  attr_accessor :file_sync
  attr_accessor :state, :last_error_message

  dependent_property :state_description, [:state, :last_error_message, 'file_sync.enabled']
  dependent_property :state_image,       [:state]

  def initialize(file_sync)
    super()
    self.file_sync = file_sync
    self.state = STATE_IDLE
    @should_stop_monitoring = false
    @run_once_more = false
    @mutex = Mutex.new
    box = file_sync.box
    @local_path = File.join Dir.home, FILE_SYNC_FOLDER_NAME, sanitize(box.name)
  end

  def state_description
    'State: ' + case @state
      when STATE_IDLE
        @file_sync.enabled ? 'Not Monitoring' : 'Disabled'
      when STATE_MONITORING
        'Monitoring'
      when STATE_SYNCING
        'Syncing'
      when STATE_ERROR
        "Error! #{@last_error_message}"
    end
  end

  def state_image
    'state-' + case @state
      when STATE_MONITORING
        'green'
      when STATE_SYNCING
        'yellow'
      when STATE_ERROR
        'red'
      else
        'gray'
    end
  end

  def start_monitoring
    puts "filesync: start_monitoring #{@file_sync.box.name}"
    @should_stop_monitoring = false
    self.state = STATE_MONITORING
    NSThread.detachNewThreadSelector :watch_fsevent, toTarget: self, withObject: nil
    NSThread.detachNewThreadSelector :start_timer, toTarget: self, withObject: nil
    do_sync
  end

  def stop_monitoring
    puts "filesync: stop_monitoring #{@file_sync.box.name}"
    @mutex.synchronize do
      @run_once_more = false
      @should_stop_monitoring = true
      stop_fsevent
      stop_timer
      self.state = STATE_IDLE
    end
  end

  def do_sync
    puts "do sync!"
    Dispatch::Queue.main.async { start }
  end

  def initialize_child_process
    box = @file_sync.box

    remote = remote_path

    args = [
      @local_path,
      remote,
      '-auto',  # auto accept default actions
      '-batch', # ask no questions
      '-perms=777', # sync all permissions
      '-confirmbigdel=false', # don't ask about whole replica deletes
      '-log=false', # don't log
      '-rsrc=false', # don't sync resource fork
      '-sshargs', '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=publickey -c blowfish-cbc',
      '-ignore', IGNORE_LIST,
      '-prefer', remote, # prefer remote when there's a conflict
    ]

    args << '-ignorearchives' unless Dir.exists? @local_path
    FileUtils.mkdir_p @local_path

    resource_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

    puts 'filesync: unison ' + args.join(' ')

    AIOChildProcess.new "#{resource_path}/actionio-unison", args
  end

  def start
    @mutex.synchronize do
      if @state == STATE_MONITORING || @state == STATE_ERROR
        puts "filesync: start unison #{@file_sync.box.name}"
        @run_once_more = false
        self.state = STATE_SYNCING
        self.last_error_message = nil
        super
      elsif @state == STATE_SYNCING
        puts "filesync: to run once more #{@file_sync.box.name}"
        @run_once_more = true
      end
    end
  end

  def kill
    super
    stop_monitoring
  end

  def restart
    raise NotSupportedError
  end

  def child_process_did_write_to_stdout(text)
    process_output text
  end

  def child_process_did_write_to_stderr(text)
    process_output text
  end

  def child_process_did_terminate(code)
    puts "filesync: child process did terminate #{@file_sync.box.name}"
    super
    if @should_stop_monitoring
      stop_monitoring
      return
    end
    self.state = STATE_MONITORING if @state == STATE_SYNCING
    if @run_once_more
      start
    end
  end

  protected
  def remote_path
    box = @file_sync.box
    "ssh://action@#{sanitize box.host}:#{box.port}/workspace"
  end

  def watch_fsevent
    @fsevent = FSEvent.new
    options = {
      latency: 1.0,
      no_defer: false,
      watch_root: false,
      file_events: true
    }
    @fsevent.watch @local_path, options do |directories|
      p directories
      do_sync
    end
    @fsevent.run unless @should_stop_monitoring
  end

  def stop_fsevent
    @fsevent.stop if @fsevent
    @fsevent = nil
  end

  def start_timer
    @timer = NSTimer.scheduledTimerWithTimeInterval FILE_SYNC_INTERVAL, target: self, selector: :do_sync, userInfo: nil, repeats: true
    runloop = NSRunLoop.currentRunLoop
    while @timer
      runloop.runMode NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture
    end
  end

  def stop_timer
    @timer.invalidate if @timer
    @timer = nil
  end

  def process_output(text)
    puts text
    if match = text.match(/[Ee]rror:(.*)$/)
      self.state = STATE_ERROR
      self.last_error_message = match[1].strip.capitalize
    end if @state == STATE_SYNCING
  end

  # just in case, to prevent arbitrary command injection
  def sanitize(name)
    name.to_s.gsub /[^a-zA-Z0-9\-\.]/, ''
  end
end
