module Kernel
  def concurrent_queue(&block)
    Dispatch::Queue.concurrent.async &block
  end

  def open_url(url)
    NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(url)
  end
end
