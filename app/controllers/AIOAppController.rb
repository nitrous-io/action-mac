require 'AIOObserver'

class AIOAppController
  include AIOObserver

  attr_accessor :status_menu_controller, :welcome_window_controller, :preferences_window_controller, :ssh_key_pair_window_controller
  attr_accessor :notifier, :task_manager, :api, :pusher, :jobs, :ssh_key_pair
  attr_accessor :current_user, :boxes, :public_keys

  dependent_property :connected, ['current_user.id', 'pusher.ready', 'boxes.last_fetch_error']

  def initialize
    Kernel.const_set :AIOApp, self

    self.notifier = AIONotifier.new
    self.task_manager = AIOTaskManager.new
    self.api = AIOAPI.new
    self.jobs = AIOJobManager.new

    NSThread.detachNewThreadSelector :start_job_timer, toTarget: self, withObject: nil

    self.pusher = AIOPusher.new

    self.ssh_key_pair = AIOSSHKeyPair.new
    concurrent_queue { @ssh_key_pair.find_keys }

    self.boxes = AIOBoxCollection.new
    self.public_keys = AIOPublicKeyCollection.new
    self.current_user = AIOUser.new

    observe(self, 'api.signed_in'  ) { |v,c| did_sign_in                v,c }
    observe(self, 'current_user.id') { |v,c| did_fetch_current_user     v,c }
    observe(self, 'pusher.ready'   ) { |v,c| connect_to_pusher_if_ready v,c }
    observe(self, 'api.oauth.accessToken') { |v,c| access_token_did_change v,c }

    sign_in_with_keychain
    open_welcome_window unless g('api.signed_in')
  end

  def finalize
    stop_job_timer
    stop_observing self, 'api.signed_in'
    stop_observing self, 'current_user.id'
    stop_observing self, 'pusher.ready'
    stop_observing self, 'api.oauth.accessToken'
  end

  def connected
    !g('current_user.id').nil? && g('pusher.ready') && g('boxes.last_fetch_error').nil?
  end

  def open_welcome_window
    self.welcome_window_controller = AIOWelcomeWindowController.new
    @welcome_window_controller.show_window
  end

  def close_welcome_window
    if @welcome_window_controller
      @welcome_window_controller.close
      self.welcome_window_controller = nil
    end
  end

  def show_status_menu
    self.status_menu_controller = AIOStatusMenuController.new
    NSBundle.loadNibNamed 'StatusMenu', owner: @status_menu_controller
    @status_menu_controller.setup_menu
  end

  def remove_status_menu
    if @status_menu_controller
      @status_menu_controller.teardown_menu
      self.status_menu_controller = nil
    end
  end

  def open_preferences_window
    self.preferences_window_controller ||= AIOPreferencesWindowController.new
    @preferences_window_controller.show_window
  end

  def close_preferences_window
    if @preferences_window_controller
      @preferences_window_controller.close
    end
  end

  def application_will_terminate(notification)
    @task_manager.kill_all if @task_manager
  end

  def sign_in_with_keychain
    begin
      @api.sign_in_with_keychain
    rescue AIOAPI::KeychainError => e
      show_keychain_error
    end
  end

  def sign_out
    begin
      @api.sign_out
      reset
    rescue AIOAPI::KeychainError => e
      Dispatch::Queue.main.async do
        show_keychain_error
      end
    end
  end

  private
  def did_sign_in(value, change)
    Dispatch::Queue.main.async do
      reset
      if value # signed in?
        show_status_menu
        fetch_current_user
      else
        remove_status_menu
        close_preferences_window
        open_welcome_window
      end
    end
  end

  def fetch_current_user
    if g('api.signed_in')
      AIOApp.current_user.fetch do |err, response|
        if err
          Dispatch::Queue.main.after(RETRY_REQUEST_INTERVAL) { fetch_current_user }
        end
      end
    end
  end

  def fetch_public_keys
    if g('api.signed_in') && g('current_user.id')
      AIOApp.public_keys.fetch do |err, response|
        return if err
        check_whether_public_key_is_registered
      end
    end
  end

  def fetch_boxes
    if g('api.signed_in') && g('current_user.id')
      AIOApp.boxes.fetch do |err, response|
        # poll for changes
        Dispatch::Queue.main.after(BOXES_FETCHING_INTERVAL) { fetch_boxes }
      end
    end
  end

  def did_fetch_current_user(value, change)
    if value # current_user.id
      fetch_public_keys
      fetch_boxes
    end
    connect_to_pusher_if_ready(value, change)
  end

  def connect_to_pusher_if_ready(value, change)
    Dispatch::Queue.main.async do
      if g('api.signed_in') && g('pusher.ready') && g('current_user.id')
        @pusher.connect
      else
        @pusher.disconnect
      end
    end
  end

  def access_token_did_change(value, change)
    if value == nil && g('api.signed_in')
      sign_out
    end
  end

  def show_keychain_error
    NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
    NSApp.terminate self
  end

  def reset
    @jobs.cancel_all
    @boxes.clear
    @public_keys.clear
    @current_user.clear
    @task_manager.kill_all
  end

  def process_jobs
    @jobs.process_jobs
  end

  def start_job_timer
    @job_timer = NSTimer.scheduledTimerWithTimeInterval JOB_PROCESSING_INTERVAL, target: self, selector: :process_jobs, userInfo: nil, repeats: true
    runloop = NSRunLoop.currentRunLoop
    while @job_timer
      runloop.runMode NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture
    end
  end

  def stop_job_timer
    @job_timer.invalidate if @job_timer
    @job_timer = nil
  end

  def check_whether_public_key_is_registered
    ssh_key_pair = AIOApp.ssh_key_pair
    ssh_key_pair.find_keys

    if ssh_key_pair.private_key_path.nil?
      Dispatch::Queue.main.async do
        self.ssh_key_pair_window_controller = AIOSSHKeyPairWindowController.new
        @ssh_key_pair_window_controller.show_generate_keypair_window
      end
      return
    end
    if ssh_key_pair.public_key_path
      ssh_key_pair.read_public_key
      md5_fingerprint = ssh_key_pair.public_key_md5_fingerprint
      return if AIOApp.public_keys.models.find { |k| k.md5_fingerprint == md5_fingerprint }
    end
    Dispatch::Queue.main.async do
      self.ssh_key_pair_window_controller = AIOSSHKeyPairWindowController.new
      @ssh_key_pair_window_controller.show_register_keypair_window
    end
  end
end
