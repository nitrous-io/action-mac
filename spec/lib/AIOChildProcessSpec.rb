require 'SpecHelper'
require 'AIOChildProcess'

class TestChildProcessDelegate
  attr_accessor :pid, :stdout, :stderr, :exit_code

  def initialize
    self.pid = nil
    self.stdout = []
    self.stderr = []
    self.exit_code = nil
  end

  def child_process_did_launch(pid)
    self.pid = pid
  end

  def child_process_did_write_to_stdout(text)
    self.stdout << text
  end

  def child_process_did_write_to_stderr(text)
    self.stderr << text
  end

  def child_process_did_terminate(code)
    self.exit_code = code
  end
end

describe AIOChildProcess do
  before do
    @child_process = AIOChildProcess.new '/usr/bin/env', ['ruby', '-e', '$stdout.puts "What is your name?";$stdout.puts "Hello, #{gets.chomp}!";$stderr.puts "stderr!!!";exit 123']
    @test_delegate = TestChildProcessDelegate.new
    @child_process.delegate = @test_delegate
  end

  it 'is not yet launched nor finished' do
    @child_process.launched.should.equal false
    @child_process.finished.should.equal false
  end

  describe 'interacting with child process' do
    before do
      @child_process.launch
    end

    after do
      @child_process.kill
    end

    it 'runs a child process, accepts stdin, and provides stdout, stderr and exit_code' do
      wait 0.2 do
        @child_process.launched.should.equal true
        @child_process.finished.should.equal false
        @child_process.pid.should.equal @child_process.instance_variable_get(:@task).processIdentifier

        @test_delegate.pid.should.equal @child_process.pid
        @test_delegate.stdout.should.be.empty
        @test_delegate.stderr.should.be.empty

        @child_process.input "Peter\n"

        wait 0.2 do
          @child_process.finished.should.equal true
          @test_delegate.stdout.join.should.equal "What is your name?\nHello, Peter!\n"
          @test_delegate.stderr.join.should.equal "stderr!!!\n"
          @test_delegate.exit_code.should.equal 123
        end
      end
    end

    describe '#terminate' do
      it 'terminates a child process' do
        wait 0.2 do
          @child_process.launched.should.equal true
          @child_process.finished.should.equal false

          wait 0.2 do
            @child_process.terminate

            wait 0.2 do
              @child_process.finished.should.equal true
              @test_delegate.stdout.join.should.equal "What is your name?\n"
              @test_delegate.stderr.should.be.empty
              @test_delegate.exit_code.should.not.equal 123
            end
          end
        end
      end
    end
  end
end
