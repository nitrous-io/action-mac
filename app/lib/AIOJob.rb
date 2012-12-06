class AIOJob
  def self.async(&block)
    Thread.new &block
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
        if AIOSettings.debug
          puts "Error: #{self}[#{name}] #{e.inspect}: #{e.message}"
          puts e.backtrace.join "\n"
        end

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
      end
    end
  end
end

# Cocoa-specific
class AIOJob
  def self.async(&block)
    # use GCD instead of Thread
    Dispatch::Queue.concurrent.async &block
  end
end if RUBY_ENGINE == 'macruby' || RUBY_ENGINE == 'rubymotion'
