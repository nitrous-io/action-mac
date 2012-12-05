require 'AIOModel'

class AIOUser < AIOModel
  attr_accessor :username, :email, :full_name

  def initialize(api)
    @api = api
  end

  def fetch
    if response = @api.request(:get, '/user')
      update_attributes response.parsed['user']
    end
  end
end
