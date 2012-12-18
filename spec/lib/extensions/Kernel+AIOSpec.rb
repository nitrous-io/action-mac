require 'SpecHelper'
require 'Kernel+AIO'

describe 'Kernel+AIO' do
  describe '#concurrent_queue' do
    it 'executes the block asynchronously with gcd concurrent queue' do
      correct_block_passed = false
      block = -> { correct_block_passed = true }
      Dispatch::Queue.concurrent.should.receive(:async).and_yield
      concurrent_queue &block
      correct_block_passed.should.equal true
    end
  end
end

