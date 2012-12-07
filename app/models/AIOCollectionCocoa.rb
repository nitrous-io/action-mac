require 'AIOCollection'

class AIOCollectionCocoa < AIOCollection
  attr_accessor :content

  def initialize
    super
    self.content = []
  end

  def models
    mutableArrayValueForKey 'content'
  end

  def api
    AIOApp.api
  end
end
