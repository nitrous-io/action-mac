require 'rake'
require 'rake/testtask'

desc 'Run all tests'
task :test do
  output = `xcodebuild -scheme Specs build`
  if output.include? '** BUILD SUCCEEDED **'
    app = output[/^Touch (.*\.app)$/,1]
    system "#{app}/Contents/MacOS/Specs"
  else
    puts output
  end
end

task default: :test
