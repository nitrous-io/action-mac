require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  dir = File.dirname(__FILE__)
  t.libs << dir << 'spec'
  t.libs.concat Dir.glob("#{dir}/app/**/*/")

  t.pattern = 'spec/**/*Spec.rb'
  t.verbose = true
end

desc 'Run all tests'
task default: :test
