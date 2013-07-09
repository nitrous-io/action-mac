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
    self.id        = nil
    self.username  = nil
    self.email     = nil
    self.full_name = nil
  end

  def fetch(&block)
    api.request(:get, '/user') do |err, response|
      update_attributes response.json['user'] unless err
      block.call(err, response) if block
    end
  end

  def fullName
    @full_name
  end
end
