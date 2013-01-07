require 'SpecHelper'

require 'AIOIntegerToStringTransformer'

describe AIOIntegerToStringTransformer do
  before do
    @transformer = AIOIntegerToStringTransformer.new
  end

  it 'is a subclass of NSValueTransformer' do
    @transformer.should.be.kind_of? NSValueTransformer
  end

  context 'transformation' do
    it 'converts 3000 to "3000"' do
      @transformer.transformedValue(3000).should.equal '3000'
    end

    it 'converts 1234 to "1234"' do
      @transformer.transformedValue(1234).should.equal '1234'
    end
  end

  context 'reverse transformation' do
    it 'converts "1234" to 1234' do
      @transformer.reverseTransformedValue('1234').should.equal 1234
    end

    it 'converts "-1234" to -1234' do
      @transformer.reverseTransformedValue('-1234').should.equal -1234
    end

    it 'converts "1234.5" to 1234' do
      @transformer.reverseTransformedValue('1234.5').should.equal 1234
    end

    it 'converts "3000foo" to 3000' do
      @transformer.reverseTransformedValue('3000foo').should.equal 3000
    end

    it 'converts "foo" to 0' do
      @transformer.reverseTransformedValue('foo').should.equal 0
    end
  end
end
