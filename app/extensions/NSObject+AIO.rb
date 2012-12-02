class NSObject
  def main_thread(&block)
    main = Dispatch::Queue.main
    if Dispatch::Queue.current.label == main.label
      yield
    else
      main.sync &block
    end
  end
end
