class AIOApplicationController
  attr_accessor :window, :menu_controller
  attr_reader :api, :jobs, :welcome_window_controller
  attr_reader :boxes

  def applicationDidFinishLaunching(notification)
    @api = AIOAPICocoa.new

    @jobs = AIOJobManager.new
    NSTimer.scheduledTimerWithTimeInterval JOB_PROCESSING_INTERVAL, target: self, selector: :process_jobs, userInfo: nil, repeats: true

    addObserver self, forKeyPath: 'api.token', options: 0, context: nil
    addObserver self, forKeyPath: 'api.signed_in', options: 0, context: nil

    begin
      @api.sign_in
    rescue AIOAPICocoa::KeychainError => e
      show_keychain_error
    end

    show_welcome_window unless @api.token
  end

  def finalize
    removeObserver self, forKeyPath: 'api.token'
    removeObserver self, forKeyPath: 'api.signed_in'
  end

  def show_welcome_window
    @welcome_window_controller = AIOWelcomeWindowController.new
    self.window = @welcome_window_controller.window
    window.makeKeyAndOrderFront nil
    window.orderFrontRegardless
  end

  def close_welcome_window
    @welcome_window_controller.close
    @welcome_window_controller = nil
  end

  def show_menu_and_close_welcome_window
    reset_collections
    close_welcome_window if @welcome_window_controller
    @menu_controller.setup_menu unless @menu_controller.status_item
  end

  def show_welcome_window_and_remove_menu
    reset_collections
    @menu_controller.teardown_menu if @menu_controller.status_item
    show_welcome_window unless @welcome_window_controller
  end

  # observer
  def observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    val = object.valueForKeyPath keyPath
    case keyPath
      when 'api.token'
        if val.nil?
          begin
            @api.sign_out
          rescue AIOAPICocoa::KeychainError => e
            main_thread do
              show_keychain_error
            end
          end
        end
      when 'api.signed_in'
        main_thread do
          if val
            show_menu_and_close_welcome_window
          else
            show_welcome_window_and_remove_menu
          end
        end
    end
  end

  private
  def show_keychain_error
    NSRunCriticalAlertPanel 'Error', 'Could not access keychain. Is your keychain locked?', 'Okay', nil, nil
    NSApp.terminate self
  end

  def reset_collections
    @boxes = AIOBoxCollection.new @api
  end

  def process_jobs
    @jobs.process_jobs
  end
end
