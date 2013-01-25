class AIOTask
  def finalize
    kill
  end

  def initialize_child_process
    raise NotImplementedError
  end

  def start
    puts "starting #{NSStringFromClass self.class} #{self}"
    @child_process = initialize_child_process
    @child_process.delegate = self

    if @child_process.kind_of? AIOChildProcess
      @child_process.launch
    end
  end

  def stop
    return unless @child_process
    puts "stopping #{NSStringFromClass self.class} #{self}"
    @child_process.terminate
  end

  def kill
    return unless @child_process
    puts "killing #{NSStringFromClass self.class} #{self}"
    AIOApp.task_manager.remove self
    @child_process.delegate = nil
    @child_process.kill
    @child_process = nil
  end

  def restart
    kill if @child_process
    start
  end

  def child_process_did_launch(pid)
    AIOApp.task_manager.add self
  end

  def child_process_did_write_to_stdout(text)
    puts text
  end

  def child_process_did_write_to_stderr(text)
    puts text
  end

  def child_process_did_terminate(code)
    AIOApp.task_manager.remove self
    @child_process.delegate = nil
    @child_process = nil
  end
end
