class AIOJob
  CompletionNotification = 'AIOJobCompletionNotification'

  def self.async(&block)
    Dispatch::Queue.concurrent.async &block
  end

  attr_reader :name, :task, :cancelled, :running, :completed, :failed, :last_error

  def initialize(name=nil, &task)
    raise ArgumentError.new('block is missing') unless block_given?
    @name = name
    @task = task
    @cancelled = false
    @running = false
    @completed = false
    @failed = false
    @mutex = Mutex.new
  end

  def cancel!
    @mutex.synchronize do
      @cancelled = true
    end
  end

  def perform
    self.class.async do
      @mutex.synchronize do
        return if @cancelled || @completed || @running
        @running = true
        @failed = false
      end
      begin
        @task.call
      rescue => e
        AIOLog "Error: #{self}[#{name}] #{e.inspect}: #{e.message}"
        AIOLog e.backtrace.join "\n"

        @mutex.synchronize do
          @last_error = e
          @failed = true
          @running = false
        end
      else
        @mutex.synchronize do
          @completed = true
          @running = false
        end
        on_complete
      end
    end
  end

  protected
  def on_complete
    NSNotificationCenter.defaultCenter.postNotificationName CompletionNotification, object: self
  end
end
