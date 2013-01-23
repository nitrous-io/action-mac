require 'AIOModel'

class AIOBox < AIOModel
  STATE_RUNNING = 'running'
  STATE_STOPPED = 'stopped'
  STATE_TERMINATED = 'terminated'
  STATE_SUSPENDED = 'suspended'
  STATE_DEFAULT = 'default'

  attr_accessor :name, :state, :host, :port

  def state_description
    "State: #{@state.capitalize}" if @state
  end

  def state_image
    'state-' + case @state
      when STATE_RUNNING
        'green'
      when STATE_STOPPED, STATE_SUSPENDED
        'red'
      when STATE_TERMINATED
        'gray'
      else
        'yellow'
    end
  end

  def can_access_box
    @state == STATE_RUNNING
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
    @state == STATE_STOPPED
  end

  def can_restart
    @state == STATE_RUNNING
  end

  def can_shut_down
    @state == STATE_RUNNING
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
  attr_accessor :ssh_tunnels
  attr_accessor :file_sync

  dependent_property :state_description,  [:state]
  dependent_property :state_image,        [:state]
  dependent_property :can_access_box,     [:state]
  dependent_property :ssh_uri,            [:host, :port]
  dependent_property :web_ide_path,       [:id]
  dependent_property :can_perform_action, [:state]
  dependent_property :can_start,          [:state]
  dependent_property :can_restart,        [:state]
  dependent_property :can_shut_down,      [:state]

  def initialize(attrs={})
    super
    self.ssh_tunnels = AIOBoxSSHTunnels.new self
    self.file_sync = AIOBoxFileSync.new self
  end
end if RUBY_ENGINE == 'macruby'
