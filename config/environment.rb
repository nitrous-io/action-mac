require 'rubygems'

require 'AIOConstants'
require 'AIOKeyValueStore'
Kernel.const_set :AIOStore, AIOKeyValueStore.new

if AIOStore.read('debug').nil?
  AIOStore.write 'debug', true
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
