require 'SpecHelper'
require 'Kernel+AIO'

describe 'Kernel+AIO' do
  describe '#concurrent_queue' do
    it 'executes the block asynchronously with gcd concurrent queue' do
      block = -> {}
      Dispatch::Queue.concurrent.should.receive(:async).with &block
      concurrent_queue &block
    end
  end
end

