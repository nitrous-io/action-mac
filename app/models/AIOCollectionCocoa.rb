require 'AIOCollection'

class AIOCollectionCocoa < AIOCollection
  attr_accessor :content

  def initialize(api)
    super
    @content = []
  end

  def models
    mutableArrayValueForKey 'content'
  end
end
