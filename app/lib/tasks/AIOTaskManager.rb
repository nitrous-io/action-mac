class AIOTaskManager
  attr_accessor :tasks

  def initialize
    self.tasks = []
  end

  def add(task)
    @tasks << task if task.kind_of? AIOTask
  end

  def remove(task)
    @tasks.delete task
  end

  def kill_all
    @tasks.each &:kill
  end
end
