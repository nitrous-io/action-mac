require 'rubygems'
require 'AIOConstants'
require 'AIOSettings'

# preload some libraries to be thread-safe
require 'faraday'
require 'faraday/request'
require 'faraday/request/authorization'
require 'faraday/request/basic_authentication'
require 'faraday/request/url_encoded'
require 'faraday/adapter/net_http'
require 'faraday/response'
require 'json'
require 'multi_json'
MultiJson.adapter

