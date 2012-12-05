require 'SpecHelper'
require 'AIOObserver'

class AIOObserverTestClass
  include AIOObserver
end

class AIOObserverTestClass2
  attr_accessor :foo, :bar
end

describe AIOObserver do
  before do
    @obj = AIOObserverTestClass.new
    @obj2 = AIOObserverTestClass2.new
  end

  describe '#observe' do
    it 'registers a callback that gets invoked when a given keypath of a given object changes' do
      foo = 0
      bar = 0

      @obj2.foo = 0
      @obj2.bar = 0

      @obj.observe @obj2, 'foo' do |value, change|
        foo = value
      end
      @obj.observe @obj2, 'bar' do |value, change|
        bar = value + change[NSKeyValueChangeOldKey]
      end

      foo.should.equal 0
      @obj2.foo = 1
      foo.should.equal 1
      @obj2.foo = 2
      foo.should.equal 2

      bar.should.equal 0
      @obj2.bar = 1
      bar.should.equal 1
      @obj2.bar = 2
      bar.should.equal 3
      @obj2.bar = 3
      bar.should.equal 5
    end

    it 'can register multiple callbacks on the same keypath/object' do
      foo = 0

      @obj.observe @obj2, 'foo' do
        foo += 1
      end
      @obj.observe @obj2, 'foo' do
        foo += 2
      end

      foo.should.equal 0
      @obj2.foo = 'lala'
      foo.should.equal 3
    end
  end

  describe '#stop_observing' do
    it 'unregisters all callbacks that get invoked when a given keypath of a given object changes' do
      foo = 0
      bar = 0

      @obj.observe @obj2, 'foo' do
        foo += 1
      end
      @obj.observe @obj2, 'foo' do
        foo += 2
      end
      @obj.observe @obj2, 'bar' do
        bar += 1
      end

      @obj.stop_observing @obj2, 'foo'

      foo.should.equal 0
      @obj2.foo = 'lala'
      foo.should.equal 0

      bar.should.equal 0
      @obj2.bar = 'lala'
      bar.should.equal 1

      @obj.stop_observing @obj2, 'bar'
      @obj2.bar = 'lalala'
      bar.should.equal 1
    end
  end
end
