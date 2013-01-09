framework 'Foundation'

class AIOChildProcess
  DidWriteToStdoutNotification = 'AIOChildProcessDidWriteToStdoutNotification'
  DidWriteToStderrNotification = 'AIOChildProcessDidWriteToStderrNotification'
  DidTerminateNotification = 'AIOChildProcessDidTerminateNotification'

  attr_reader :launched, :finished

  def initialize(path, arguments)
    @launched = false
    @finished = false

    @task = NSTask.alloc.init
    @task.setLaunchPath path
    @task.setArguments arguments

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
  end

  def launch
    return if @launched
    @launched = true
    notification_center = NSNotificationCenter.defaultCenter
    notification_center.addObserver self, selector: 'get_stdout:', name: NSFileHandleReadCompletionNotification, object: @stdout_handle
    notification_center.addObserver self, selector: 'get_stderr:', name: NSFileHandleReadCompletionNotification, object: @stderr_handle
    notification_center.addObserver self, selector: 'task_did_terminate:', name: NSTaskDidTerminateNotification, object: @task

    @stdout_handle.readInBackgroundAndNotify
    @stderr_handle.readInBackgroundAndNotify
    @task.launch
  end

  def input(string)
    data = string.dataUsingEncoding NSUTF8StringEncoding
    @stdin_handle.writeData data
  end

  def terminate
    @task.terminate
  end

  private
  def get_stdout(notification)
    if output = get_output_string(notification)
      NSNotificationCenter.defaultCenter.postNotificationName DidWriteToStdoutNotification, object: self, userInfo: { data: output }
      @stdout_handle.readInBackgroundAndNotify
    else
      @stdout_empty = true
      finish
    end
  end

  def get_stderr(notification)
    if output = get_output_string(notification)
      NSNotificationCenter.defaultCenter.postNotificationName DidWriteToStderrNotification, object: self, userInfo: { data: output }
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
      @finished = true
      notification_center = NSNotificationCenter.defaultCenter
      notification_center.removeObserver self, name: NSFileHandleReadCompletionNotification, object: @stdout_handle
      notification_center.removeObserver self, name: NSFileHandleReadCompletionNotification, object: @stderr_handle
      notification_center.removeObserver self, name: NSTaskDidTerminateNotification, object: @task
      notification_center.postNotificationName DidTerminateNotification, object: self, userInfo: { code: @task.terminationStatus }
    end
  end
end
