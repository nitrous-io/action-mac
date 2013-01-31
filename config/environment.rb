require 'rubygems'

resource_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
ENV['BUNDLE_GEMFILE'] = File.join resource_path, 'Gemfile'

require 'bundler'
Bundler.require

require 'AIOConstants'
require 'AIOSettings'
require 'Kernel+AIO'
require 'NSObject+AIO'

# preload some autoloaded libraries to be thread-safe
require 'faraday'
require 'faraday/utils'
require 'faraday/connection'
require 'faraday/builder'
require 'faraday/request'
require 'faraday/response'
require 'faraday/middleware'
require 'faraday/adapter'
require 'faraday/error'
require 'faraday/request/url_encoded'
require 'faraday/adapter/net_http'

require 'json'
require 'multi_json'
MultiJson.adapter
