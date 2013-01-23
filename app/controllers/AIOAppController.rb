require 'AIOObserver'

class AIOAppController
  include AIOObserver

  attr_accessor :status_menu_controller, :welcome_window_controller, :preferences_window_controller
  attr_accessor :store, :task_manager, :api, :pusher, :jobs, :ssh_key_pair
  attr_accessor :current_user, :boxes, :public_keys

  def initialize
    Kernel.const_set :AIOApp, self

    self.store = AIOKeyValueStore.new
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

    observe(self, 'api.token'      ) { |v,c| sign_out_if_token_becomes_nil v,c }
    observe(self, 'api.signed_in'  ) { |v,c| switch_view_on_sign_in_or_out v,c }
    observe(self, 'current_user.id') { |v,c| connect_to_pusher_when_ready  v,c }
    observe(self, 'pusher.ready'   ) { |v,c| connect_to_pusher_when_ready  v,c }

    begin
      @api.sign_in
    rescue AIOAPI::KeychainError => e
      show_keychain_error
    end

    open_welcome_window unless @api.token
  end

  def finalize
    stop_job_timer
    stop_observing self, 'api.token'
    stop_observing self, 'api.signed_in'
    stop_observing self, 'current_user.id'
    stop_observing self, 'pusher.ready'
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

  private
  def sign_out_if_token_becomes_nil(value, change)
    if value.nil?
      begin
        @api.sign_out
      rescue AIOAPI::KeychainError => e
        Dispatch::Queue.main.async do
          show_keychain_error
        end
      end
    end
  end

  def switch_view_on_sign_in_or_out(value, change)
    Dispatch::Queue.main.async do
      reset
      if value
        close_welcome_window
        show_status_menu
      else
        remove_status_menu
        close_preferences_window
        open_welcome_window
      end
    end
  end

  def connect_to_pusher_when_ready(value, change)
    Dispatch::Queue.main.async do
      if g('pusher.ready') && g('current_user.id')
        @pusher.connect
      else
        @pusher.disconnect
      end
    end
  end

  def show_keychain_error
    NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
    NSApp.terminate self
  end

  def reset
    @jobs.cancel_all
    @boxes.clear
    @current_user.clear
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
end
