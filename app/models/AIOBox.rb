require 'AIOModel'

class AIOBox < AIOModel
  attr_accessor :name, :state, :host, :port

  def state_description
    "State: #{@state.capitalize}" if @state
  end

  def state_image
    'state-' + case @state
      when 'running', 'stopped', 'terminated'
        @state
      when 'suspended'
        'stopped'
      else
        'default'
    end
  end

  def can_access_box
    @state == 'running'
  end

  def ssh_uri
    "ssh://action@#{@host}:#{@port}" if @host && @port
  end

  def web_ide_uri
    "/app#/boxes/#{@id}/ide" if @id
  end
end

# Cocoa-specific
class AIOBox
  dependent_property :state_description,  [:state]
  dependent_property :state_image,        [:state]
  dependent_property :can_access_box,     [:state]
  dependent_property :ssh_uri,     [:host, :port]
  dependent_property :web_ide_uri, [:id]
end if RUBY_ENGINE == 'macruby' || RUBY_ENGINE == 'rubymotion'
