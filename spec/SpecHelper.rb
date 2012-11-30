require 'rubygems'
gem 'mac_bacon'
gem 'facon'

require 'mac_bacon'
require 'facon'

dir = File.dirname(__FILE__)
$: << dir << "#{dir}/.." << "#{dir}/support" << "#{dir}/../config"
$:.concat Dir.glob("#{dir}/../app/**/*/")
$:.concat Dir.glob("#{dir}/../vendor/**/*/")

require 'environment'

module Bacon
  class Context
    alias_method :context, :describe
  end
end

module Facon
  module Mockable
    alias_method :stub, :stub!
  end
end

