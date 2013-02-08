class AIOTaskManager
  attr_accessor :tasks

  def initialize
    self.tasks = []
  end

  def add(task)
    AIOLog "adding task: #{task}"
    @tasks << task if task.kind_of? AIOTask
  end

  def remove(task)
    AIOLog "removing task: #{task}"
    @tasks.delete task
  end

  def kill_all
    @tasks.dup.each &:kill
  end
end
