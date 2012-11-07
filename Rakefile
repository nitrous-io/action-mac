require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << File.dirname(__FILE__) << 'app' << 'spec'
  t.test_files = FileList['spec/**/*Spec.rb']
  t.verbose = true
end

desc 'Run all tests'
task default: :test
