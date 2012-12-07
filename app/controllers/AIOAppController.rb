require 'AIOObserver'

class AIOAppController
  include AIOObserver

  attr_accessor :status_menu_controller, :welcome_window_controller
  attr_accessor :api, :pusher, :jobs
  attr_accessor :current_user, :boxes

  def initialize
    Kernel.const_set :AIOApp, self

    self.api = AIOAPICocoa.new
    self.jobs = AIOJobManager.new
    NSTimer.scheduledTimerWithTimeInterval JOB_PROCESSING_INTERVAL, target: self, selector: :process_jobs, userInfo: nil, repeats: true
    self.pusher = AIOPusher.new

    observe(self, 'api.token'      ) { |v,c| sign_out_if_token_is_invalid  v,c }
    observe(self, 'api.signed_in'  ) { |v,c| switch_view_on_sign_in_or_out v,c }
    observe(self, 'current_user.id') { |v,c| connect_to_pusher_when_ready  v,c }
    observe(self, 'pusher.ready'   ) { |v,c| connect_to_pusher_when_ready  v,c }

    begin
      @api.sign_in
    rescue AIOAPICocoa::KeychainError => e
      show_keychain_error
    end

    show_welcome_window unless @api.token
  end

  def finalize
    stop_observing self, 'api.token'
    stop_observing self, 'api.signed_in'
    stop_observing self, 'current_user.id'
    stop_observing self, 'pusher.ready'
  end

  def show_welcome_window
    self.welcome_window_controller = AIOWelcomeWindowController.new
    window = @welcome_window_controller.window
    window.makeKeyAndOrderFront nil
    window.orderFrontRegardless
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

  private
  def sign_out_if_token_is_invalid(value, change)
    if value.nil?
      begin
        @api.sign_out
      rescue AIOAPICocoa::KeychainError => e
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
        show_welcome_window
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

  def reset_collections
    self.boxes = AIOBoxCollection.new
    self.current_user = AIOUser.new
  end

  def reset
    @jobs.cancel_all
    reset_collections
  end

  def process_jobs
    @jobs.process_jobs
  end
end
