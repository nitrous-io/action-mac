require 'rake'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  require 'rubygems'
  require 'mac_bacon'

  dir = File.dirname(__FILE__)
  files = Dir.glob("#{dir}/spec/**/*Spec.rb")
  files.each { |f| load f }

  Bacon.extend Bacon::TestUnitOutput
  Bacon.run
end

task default: :test

