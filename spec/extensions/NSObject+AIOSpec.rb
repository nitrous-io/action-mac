require 'SpecHelper'
require 'NSObject+AIO'

describe 'NSObject+AIO' do
  describe '#main_thread' do
    context 'when already on main thread' do
      before do
        mock_main_queue = mock :main_queue, label: Dispatch::Queue.main.label
        Dispatch::Queue.stub(:current).and_return mock_main_queue
      end

      it 'executes a given block in the current thread' do
        Dispatch::Queue.main.should.not.receive :sync
        a = 0
        main_thread do
          a = 1
        end
        a.should.equal 1
      end
    end

    context 'when not on main thread' do
      before do
        @mock_main_queue = mock :main_queue, label: Dispatch::Queue.main.label
        Dispatch::Queue.stub(:current).and_return Dispatch::Queue.concurrent
        Dispatch::Queue.stub(:main).and_return @mock_main_queue
      end

      it 'executes a given block by queueing in the main thread' do
        a = 0
        block = -> { a = 1 }
        @mock_main_queue.should.receive(:sync).and_yield
        main_thread &block
        a.should.equal 1
      end
    end
  end

  describe '#concurrent_queue' do
    it 'executes the block asynchronously with gcd concurrent queue' do
      block = -> {}
      Dispatch::Queue.concurrent.should.receive(:async).with &block
      concurrent_queue &block
    end
  end
end

