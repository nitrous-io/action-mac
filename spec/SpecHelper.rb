require 'rubygems'
gem 'minitest'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'

module Kernel
  alias_method :context, :describe
end
