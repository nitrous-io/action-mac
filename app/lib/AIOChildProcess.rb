framework 'Foundation'

class AIOChildProcess
  attr_accessor :delegate
  attr_reader :launched, :finished

  def initialize(path, arguments)
    @launched = false
    @finished = false

    @path = path
    @arguments = arguments
  end

  def finalize
    NSNotificationCenter.defaultCenter.removeObserver self
  end

  def pid
    @task.processIdentifier if @task
  end

  def launch
    return if @launched
    @launched = true

    @task = NSTask.alloc.init
    @task.setLaunchPath @path
    @task.setArguments @arguments

    @stdin_pipe  = NSPipe.alloc.init
    @stdout_pipe = NSPipe.alloc.init
    @stderr_pipe = NSPipe.alloc.init

    @task.setStandardInput  @stdin_pipe
    @task.setStandardOutput @stdout_pipe
    @task.setStandardError  @stderr_pipe

    @stdin_handle = @stdin_pipe.fileHandleForWriting
    @stdout_handle = @stdout_pipe.fileHandleForReading
    @stderr_handle = @stderr_pipe.fileHandleForReading

    @stdout_empty = false
    @stderr_empty = false

    notification_center = NSNotificationCenter.defaultCenter
    notification_center.addObserver self, selector: 'get_stdout:', name: NSFileHandleReadCompletionNotification, object: @stdout_handle
    notification_center.addObserver self, selector: 'get_stderr:', name: NSFileHandleReadCompletionNotification, object: @stderr_handle
    notification_center.addObserver self, selector: 'task_did_terminate:', name: NSTaskDidTerminateNotification, object: @task

    NSThread.detachNewThreadSelector :run_task, toTarget: self, withObject: nil
  end

  def input(string)
    if @stdin_handle
      data = string.dataUsingEncoding NSUTF8StringEncoding
      @stdin_handle.writeData data
    end
  end

  def terminate
    @task.terminate unless @finished
  end

  def kill
    id = pid
    if id && id != 0
      begin
        Process.kill 'KILL', id
      rescue
      end
    end
  end

  private
  def run_task
    @stdout_handle.readInBackgroundAndNotify
    @stderr_handle.readInBackgroundAndNotify

    @task.launch

    Dispatch::Queue.main.async do
      if @delegate && @delegate.respond_to?(:child_process_did_launch)
        @delegate.child_process_did_launch @task.processIdentifier
      end
    end

    @task.waitUntilExit

    runloop = NSRunLoop.currentRunLoop
    while !@finished
      runloop.runMode NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture
    end
  end

  def get_stdout(notification)
    if output = get_output_string(notification)
      Dispatch::Queue.main.async do
        if @delegate && @delegate.respond_to?(:child_process_did_write_to_stdout)
          @delegate.child_process_did_write_to_stdout output
        end
      end

      @stdout_handle.readInBackgroundAndNotify
    else
      @stdout_empty = true
      finish
    end
  end

  def get_stderr(notification)
    if output = get_output_string(notification)
      Dispatch::Queue.main.async do
        if @delegate && @delegate.respond_to?(:child_process_did_write_to_stderr)
          @delegate.child_process_did_write_to_stderr output
        end
      end

      @stderr_handle.readInBackgroundAndNotify
    else
      @stderr_empty = true
      finish
    end
  end

  def get_output_string(notification)
    data = notification.userInfo[NSFileHandleNotificationDataItem]
    NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding) if data.length > 0
  end

  def task_did_terminate(notification)
    finish
  end

  def finish
    if @stdout_empty && @stderr_empty && !@task.isRunning
      notification_center = NSNotificationCenter.defaultCenter
      notification_center.removeObserver self, name: NSFileHandleReadCompletionNotification, object: @stdout_handle
      notification_center.removeObserver self, name: NSFileHandleReadCompletionNotification, object: @stderr_handle
      notification_center.removeObserver self, name: NSTaskDidTerminateNotification, object: @task

      Dispatch::Queue.main.async do
        if @delegate && @delegate.respond_to?(:child_process_did_terminate)
          @delegate.child_process_did_terminate @task.terminationStatus
        end
      end

      @finished = true
    end
  end
end
