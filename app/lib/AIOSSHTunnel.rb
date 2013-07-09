class AIOSSHTunnel
  attr_accessor :origin_port

  def initialize(origin_port=3000)
    self.origin_port = origin_port
  end

  def destination_host
    'localhost'
  end

  def destination_port
    origin_port
  end
end
