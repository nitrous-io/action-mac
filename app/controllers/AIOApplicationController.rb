require 'AIOObserver'

class AIOApplicationController
  include AIOObserver

  attr_accessor :window, :menu_controller
  attr_accessor :api, :current_user, :boxes
  attr_reader :jobs, :pusher
  attr_reader :welcome_window_controller

  def applicationDidFinishLaunching(notification)
    @api = AIOAPICocoa.new

    @jobs = AIOJobManager.new
    NSTimer.scheduledTimerWithTimeInterval JOB_PROCESSING_INTERVAL, target: self, selector: :process_jobs, userInfo: nil, repeats: true

    @pusher = AIOPusher.new

    observe(self, 'api.token') { |v,c| api_token_did_change v,c }
    observe(self, 'api.signed_in') { |v,c| api_signed_in_did_change v,c }
    observe(self, 'current_user.id') { |v,c| current_user_id_did_change v,c }

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
  end

  def show_welcome_window
    @welcome_window_controller ||= AIOWelcomeWindowController.new
    self.window = @welcome_window_controller.window
    window.makeKeyAndOrderFront nil
    window.orderFrontRegardless
  end

  def close_welcome_window
    @welcome_window_controller.close
    @welcome_window_controller = nil
  end

  private
  def api_token_did_change(value, change)
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

  def api_signed_in_did_change(value, change)
    Dispatch::Queue.main.async do
      reset
      if value
        close_welcome_window if @welcome_window_controller
        @menu_controller.setup_menu unless @menu_controller.status_item
      else
        @menu_controller.teardown_menu if @menu_controller.status_item
        show_welcome_window unless @welcome_window_controller
      end
    end
  end

  def current_user_id_did_change(value, change)
    Dispatch::Queue.main.async do
      if value
        @pusher.connect
      else
        @pusher.disconnect
      end
    end
  end

  private
  def show_keychain_error
    NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
    NSApp.terminate self
  end

  def reset_collections
    self.boxes = AIOBoxCollection.new @api
    self.current_user = AIOUser.new @api
  end

  def reset
    @jobs.cancel_all
    reset_collections
  end

  def process_jobs
    @jobs.process_jobs
  end
end
