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

  def web_ide_path
    "/app#/boxes/#{@id}/ide" if @id
  end

  def can_perform_action
    can_start || can_restart || can_shut_down
  end

  def can_start
    @state == 'stopped'
  end

  def can_restart
    @state == 'running'
  end

  def can_shut_down
    @state == 'running'
  end

  def start
    api.request :put, "/boxes/#{@id}/start"
  end

  def restart
    api.request :put, "/boxes/#{@id}/restart"
  end

  def shut_down
    api.request :put, "/boxes/#{@id}/stop"
  end
end

# Cocoa-specific
class AIOBox
  dependent_property :state_description,  [:state]
  dependent_property :state_image,        [:state]
  dependent_property :can_access_box,     [:state]
  dependent_property :ssh_uri,            [:host, :port]
  dependent_property :web_ide_path,       [:id]
  dependent_property :can_perform_action, [:state]
  dependent_property :can_start,          [:state]
  dependent_property :can_restart,        [:state]
  dependent_property :can_shut_down,      [:state]
end if RUBY_ENGINE == 'macruby'
