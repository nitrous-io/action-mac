require 'SpecHelper'

require 'AIOBooleanToNumberTransformer'

describe AIOBooleanToNumberTransformer do
  before do
    @transformer = AIOBooleanToNumberTransformer.new
  end

  it 'is a subclass of NSValueTransformer' do
    @transformer.should.be.kind_of? NSValueTransformer
  end

  context 'transformation' do
    it 'converts false to 0' do
      @transformer.transformedValue(false).should.equal 0
    end

    it 'converts true to 1' do
      @transformer.transformedValue(true).should.equal 1
    end
  end

  context 'reverse transformation' do
    it 'converts 0 to false' do
      @transformer.reverseTransformedValue(0).should.equal false
    end

    it 'converts non-zero to true' do
      @transformer.reverseTransformedValue(1).should.equal true
      @transformer.reverseTransformedValue(2).should.equal true
      @transformer.reverseTransformedValue(-1).should.equal true
    end
  end
end
