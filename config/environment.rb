require 'rubygems'

require 'AIOConstants'
require 'AIOKeyValueStore'
Kernel.const_set :AIOStore, AIOKeyValueStore.new

if AIOStore.read('debug').nil?
  AIOStore.write 'debug', true
end

add_as_login_item = AIOStore.read('add_as_login_item')
if add_as_login_item
  AIOLoginItem.addAppToLoginItems
elsif add_as_login_item.nil?
  AIOStore.write 'add_as_login_item', true
  AIOLoginItem.addAppToLoginItems
end

if AIOStore.read('show_desktop_notifications').nil?
  AIOStore.write 'show_desktop_notifications', true
end

def AIOLog(message=nil)
  if message && AIOStore.read('debug')
    NSLog message.kind_of?(String) ? message : message.inspect
  end
end

require 'AIOSettings'

resource_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
ENV['BUNDLE_GEMFILE'] = File.join resource_path, 'Gemfile'

require 'bundler'
Bundler.require

require 'Kernel+AIO'
require 'NSObject+AIO'
