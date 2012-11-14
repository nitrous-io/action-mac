require 'SpecHelper'
require 'AIOBooleanToNumberTransformer'

describe AIOBooleanToNumberTransformer do
  before do
    @transformer = AIOBooleanToNumberTransformer.new
  end

  it 'is a subclass of NSValueTransformer' do
    @transformer.must_be_kind_of NSValueTransformer
  end

  describe 'transformation' do
    it 'converts false to 0' do
      @transformer.transformedValue(false).must_equal 0
    end

    it 'converts true to 1' do
      @transformer.transformedValue(true).must_equal 1
    end
  end

  describe 'reverse transformation' do
    it 'converts 0 to false' do
      @transformer.reverseTransformedValue(0).must_equal false
    end

    it 'converts non-zero to true' do
      @transformer.reverseTransformedValue(1).must_equal true
      @transformer.reverseTransformedValue(2).must_equal true
      @transformer.reverseTransformedValue(-1).must_equal true
    end
  end
end
