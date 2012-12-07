require 'SpecHelper'
require 'AIOCollectionCocoa'
require 'AIOModel'

describe AIOCollectionCocoa do
  before do
    @api = mock 'api'
    @collection = AIOCollectionCocoa.new
  end

  it 'is a subclass of AIOCollection' do
    AIOCollectionCocoa.superclass.should.equal AIOCollection
  end

  describe 'content property' do
    it 'is empty by default' do
      @collection.content.should.equal []
    end
  end

  describe '#models' do
    it 'returns a mutable array proxy for the underlying content array' do
      @collection.models.should.not.be.identical_to @collection.content
      @collection.models.should.be.identical_to @collection.mutableArrayValueForKey('content')
    end
  end
end
