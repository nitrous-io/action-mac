require 'AIOModel'

class AIOUser < AIOModel
  dependent_property :username_and_full_name, [:username, :full_name]

  attr_accessor :username, :email, :full_name

  def username_and_full_name
    if @username
      return "#{@username} (#{@full_name})" if @full_name
      @username
    end
  end

  def clear
    self.username  = nil
    self.email     = nil
    self.full_name = nil
  end

  def fetch
    if response = api.request(:get, '/user')
      update_attributes response.parsed['user']
    end
  end
end
