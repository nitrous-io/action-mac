class AIOSSHTunnel
  attr_accessor :origin_port, :destination_host, :destination_port

  def initialize(origin_port=3000, destination_host='localhost', destination_port=3000)
    self.origin_port = origin_port
    self.destination_host = destination_host
    self.destination_port = destination_port
  end
end
