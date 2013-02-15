class Foo
  attr_accessor :state_description
end

class AIOBoxMenuController
  attr_accessor :box, :menu_item

  def initialize(box)
    self.box = box
  end

  def open_shell(sender)
    open_url @box.ssh_uri
  end

  def open_web_ide(sender)
    concurrent_queue do
      AIOApp.api.sign_in_to_actionio_web_app_and_open @box.web_ide_path
    end
  end

  def start(sender)
    concurrent_queue do
      @box.start
    end
  end

  def restart(sender)
    concurrent_queue do
      @box.restart
    end
  end

  def shut_down(sender)
    concurrent_queue do
      @box.shut_down
    end
  end

  def tunneling_enable_tunneling(sender)
    @box.ssh_tunnels.enabled = true
  end

  def tunneling_disable_tunneling(sender)
    @box.ssh_tunnels.enabled = false
  end

  def file_sync_enable_file_sync(sender)
    @box.file_sync.enabled = true
  end

  def file_sync_disable_file_sync(sender)
    @box.file_sync.enabled = false
  end

  def file_sync_sync_now(sender)
    @box.file_sync.file_sync_task.do_sync
  end
end
