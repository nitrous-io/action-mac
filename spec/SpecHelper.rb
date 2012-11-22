require 'rubygems'
gem 'mac_bacon'
gem 'mocha-on-bacon'

dir = File.dirname(__FILE__)
$: << dir << "#{dir}/.."
$:.concat Dir.glob("#{dir}/../app/**/*/")

module Bacon
  class Context
    alias_method :context, :describe
  end
end
