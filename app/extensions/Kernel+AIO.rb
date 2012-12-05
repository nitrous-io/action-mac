module Kernel
  def main_thread(&block)
    main = Dispatch::Queue.main
    if Dispatch::Queue.current.label == main.label
      yield
    else
      main.sync &block
    end
  end

  def concurrent_queue(&block)
    Dispatch::Queue.concurrent.async &block
  end
end
