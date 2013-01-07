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

    describe 'option "always"' do
      context 'when not given' do
        it 'does not notify when change[NSKeyValueChangeOldKey] and change[NSKeyValueChangeNewKey] have the same value' do
          notification_received = false
          @obj2.foo = 0
          @obj.observe @obj2, 'foo' do |value, change|
            notification_received = true
          end
          @obj2.foo = 0
          notification_received.should.equal false
        end
      end

      context 'when false' do
        it 'does not notify when change[NSKeyValueChangeOldKey] and change[NSKeyValueChangeNewKey] have the same value' do
          notification_received = false
          @obj2.foo = 0
          @obj.observe @obj2, 'foo' do |value, change|
            notification_received = true
          end
          @obj2.foo = 0
          notification_received.should.equal false
        end
      end

      context 'when true' do
        it 'notifies even when change[NSKeyValueChangeOldKey] and change[NSKeyValueChangeNewKey] have the same value' do
          notification_received = false
          @obj2.foo = 0
          @obj.observe @obj2, 'foo', always: true do |value, change|
            notification_received = true
          end
          @obj2.foo = 0
          notification_received.should.equal true
        end
      end
    end

    describe 'option "initial"' do
      context 'when not given' do
        it 'does not send an initial notification' do
          foo = 0
          @obj2.foo = 1

          foo.should.equal 0

          @obj.observe @obj2, 'foo' do |value, change|
            foo = value
          end

          foo.should.equal 0
        end
      end

      context 'when false' do
        it 'does not send an initial notification' do
          foo = 0
          @obj2.foo = 1

          foo.should.equal 0

          @obj.observe @obj2, 'foo', initial: false do |value, change|
            foo = value
          end

          foo.should.equal 0
        end
      end

      context 'when true' do
        it 'sends an initial notification' do
          foo = 0
          @obj2.foo = 1

          foo.should.equal 0

          @obj.observe @obj2, 'foo', initial: true do |value, change|
            foo = value
          end

          foo.should.equal 1
        end

        it 'does not affect prior observations on same target and keypath that has option initial: false' do
          foo = 0
          bar = 0
          baz = 0

          @obj2.foo = 1

          foo.should.equal 0
          bar.should.equal 0

          @obj.observe @obj2, 'foo', initial: true do |value, change|
            foo = value
          end
          foo.should.equal 1

          @obj.observe @obj2, 'foo', initial: false do |value, change|
            bar = value
          end
          bar.should.equal 0

          @obj.observe @obj2, 'foo', initial: true do |value, change|
            baz = value
          end
          baz.should.equal 1
        end
      end
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
