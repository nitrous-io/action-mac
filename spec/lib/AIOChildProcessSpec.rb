require 'SpecHelper'
require 'AIOChildProcess'

class ChildProcessTest
  attr_accessor :stdout, :stderr, :exit_code

  def initialize
    self.stdout = []
    self.stderr = []
    self.exit_code = nil
  end

  def did_write_to_stdout(notification)
    data = notification.userInfo[:data]
    self.stdout << data
  end

  def did_write_to_stderr(notification)
    data = notification.userInfo[:data]
    self.stderr << data
  end

  def did_terminate(notification)
    self.exit_code = notification.userInfo[:code]
  end
end

describe AIOChildProcess do
  before do
    @child_process = AIOChildProcess.new '/usr/bin/env', ['ruby', '-e', '$stdout.puts "What is your name?";$stdout.puts "Hello, #{gets.chomp}!";$stderr.puts "stderr!!!";exit 123']
    @test_class = ChildProcessTest.new
  end

  it 'is not yet launched nor finished' do
    @child_process.launched.should.equal false
    @child_process.finished.should.equal false
  end

  describe 'interacting with child process' do
    before do
      notification_center = NSNotificationCenter.defaultCenter
      notification_center.addObserver @test_class, selector: 'did_write_to_stdout:', name: AIOChildProcess::DidWriteToStdoutNotification, object: @child_process
      notification_center.addObserver @test_class, selector: 'did_write_to_stderr:', name: AIOChildProcess::DidWriteToStderrNotification, object: @child_process
      notification_center.addObserver @test_class, selector: 'did_terminate:', name: AIOChildProcess::DidTerminateNotification, object: @child_process
      @child_process.launch
    end

    after do
      notification_center = NSNotificationCenter.defaultCenter
      notification_center.removeObserver @test_class, name: AIOChildProcess::DidWriteToStdoutNotification, object: @child_process
      notification_center.removeObserver @test_class, name: AIOChildProcess::DidWriteToStderrNotification, object: @child_process
      notification_center.removeObserver @test_class, name: AIOChildProcess::DidTerminateNotification, object: @child_process
    end

    it 'runs a child process, accepts stdin, and provides stdout, stderr and exit_code' do
      @child_process.launched.should.equal true
      @child_process.finished.should.equal false
      @test_class.stdout.should.be.empty
      @test_class.stderr.should.be.empty

      @child_process.input "Peter\n"

      wait 0.2 do
        @child_process.finished.should.equal true
        @test_class.stdout.join.should.equal "What is your name?\nHello, Peter!\n"
        @test_class.stderr.join.should.equal "stderr!!!\n"
        @test_class.exit_code.should.equal 123
      end
    end

    describe '#terminate' do
      it 'terminates a child process' do
        @child_process.launched.should.equal true
        @child_process.finished.should.equal false

        wait 0.2 do
          @child_process.terminate

          wait 0.2 do
            @child_process.finished.should.equal true
            @test_class.stdout.join.should.equal "What is your name?\n"
            @test_class.stderr.should.be.empty
            @test_class.exit_code.should.not.equal 123
          end
        end
      end
    end
  end
end
