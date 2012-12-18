require 'SpecHelper'
require 'AIOJob'

describe AIOJob do
  describe 'constructor' do
    context 'when given a block' do
      context 'when given a name' do
        it 'creates a job object with a name' do
          block = -> {}
          job = AIOJob.new 'my-job', &block
          job.name.should.equal 'my-job'
          job.task.should.equal block
          job.cancelled.should.equal false
          job.running.should.equal false
          job.completed.should.equal false
          job.failed.should.equal false
          job.last_error.should.be.nil
        end
      end

      context 'when not given a name' do
        it 'creates a job object without a name' do
          block = -> {}
          job = AIOJob.new &block
          job.name.should.be.nil
          job.task.should.equal block
          job.cancelled.should.equal false
          job.running.should.equal false
          job.completed.should.equal false
          job.failed.should.equal false
          job.last_error.should.be.nil
        end
      end
    end

    context 'when not given a block' do
      it 'raises an error' do
        -> {
          job = AIOJob.new
        }.should.raise ArgumentError
        -> {
          job = AIOJob.new 'job-name'
        }.should.raise ArgumentError
      end
    end
  end

  describe '.async' do
    it 'runs the block asynchronously' do
      @fruit = 'apple'
      m = Monitor.new
      m.synchronize do
        AIOJob.async do
          m.synchronize { @fruit = 'orange' }
        end
        @fruit.should.equal 'apple'
      end
      sleep 0.2
      @fruit.should.equal 'orange'
    end
  end

  describe '#cancel' do
    before do
      @job = AIOJob.new {}
    end

    it 'mark job as cancelled' do
      @job.cancel!
      @job.cancelled.should.equal true
    end
  end

  describe '#perform' do
    before do
      @fruit = 'apple'
      @job = AIOJob.new do
        @fruit = 'orange'
        @job.running.should.equal true
      end
      AIOJob.should.receive(:async).and_yield
    end

    context 'when cancelled' do
      it 'does not run the task' do
        @job.cancel!
        @job.should.not.receive :on_complete
        @job.perform
        @fruit.should.equal 'apple'
        @job.running.should.equal false
        @job.completed.should.equal false
        @job.failed.should.equal false
        @job.last_error.should.be.nil
      end
    end

    context 'when not cancelled' do
      it 'marks job as running, runs the task, and marks job as completed and no longer running, and calls on_complete' do
        @job.should.receive :on_complete
        @job.perform
        @fruit.should.equal 'orange'
        @job.running.should.equal false
        @job.completed.should.equal true
        @job.failed.should.equal false
        @job.last_error.should.be.nil
      end

      context 'with a failed job' do
        before do
          @job = AIOJob.new do
            @fruit = 'orange'
            @job.failed.should.equal false
            @job.running.should.equal true
          end
        end

        it 'marks job as running, runs the task, and marks job as completed and no longer running, and calls on_complete' do
          @job.should.receive :on_complete
          @job.instance_variable_set :@failed, false
          @job.perform
          @fruit.should.equal 'orange'
          @job.running.should.equal false
          @job.completed.should.equal true
          @job.failed.should.equal false
          @job.last_error.should.be.nil
        end
      end

      context 'when task raises an exception' do
        before do
          @error = StandardError.new 'some error'
          @job = AIOJob.new do
            @job.running.should.equal true
            raise @error
          end
        end

        it 'marks job as failed, and records last error' do
          @job.should.not.receive :on_complete
          @job.perform
          @job.running.should.equal false
          @job.completed.should.equal false
          @job.failed.should.equal true
          @job.last_error.should.equal @error
        end
      end
    end
  end
end

