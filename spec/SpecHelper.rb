require 'rubygems'

require 'mac_bacon'
require 'facon'
require 'fakefs/safe'

dir = File.dirname(__FILE__)
$: << dir << "#{dir}/.." << "#{dir}/support" << "#{dir}/../config"
$:.concat Dir.glob("#{dir}/../app/**/*/")
$:.concat Dir.glob("#{dir}/../vendor/**/*/")

require 'FakeAIOSettings'
require 'environment'

def mass_set(obj, attrs)
  attrs.each_pair do |k, v|
    if obj.respond_to? :"#{k}="
      obj.send :"#{k}=", v
    else
      obj.instance_variable_set :"@#{k}", v
    end
  end
  obj
end

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

