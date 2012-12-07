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
    AIOApp.jobs.add_new 'open_shell' do
      AIOApp.api.sign_in_to_actionio_web_app_and_open @box.web_ide_uri
    end
  end
end
