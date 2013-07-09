class AIOBoxSSHTunnels
  include AIOObserver

  ORIGIN_PORT_KEY = 'origin_port'
  DESTINATION_HOST_KEY = 'destination_host'
  DESTINATION_PORT_KEY = 'destination_port'

  attr_accessor :box
  attr_accessor :local_tunnels
  attr_accessor :ssh_tunnel_task
  attr_accessor :enabled

  def initialize(box)
    self.enabled = false
    self.box = box
    load_data
    observe(self, 'local_tunnels', initial: true) { |v,c| tunnels_array_did_change v,c }
    observe(self, 'enabled', initial: true) { |v,c| enabled_did_change v,c }
    observe(@box, 'state',   initial: true) { |v,c| box_state_did_change v,c }
    observe(AIOApp, 'connected') { |v,c| connected_did_change v,c }

    self.ssh_tunnel_task = AIOSSHTunnelTask.new self
    start_or_kill_ssh_tunnel_task
  end

  def finalize
    stop_observing self, 'local_tunnels'
    stop_observing self, 'enabled'
    stop_observing @box, 'state'
    stop_observing AIOApp, 'connected'
  end

  private
  def load_data
    self.enabled = AIOStore.read(tunnels_enabled_key) || false
    self.local_tunnels  = parse_tunnels_hash_array(AIOStore.read local_tunnels_key)  || []
  end

  def save_tunnels
    AIOStore.write local_tunnels_key, tunnel_objects_to_hash_array(self.local_tunnels)
  end

  def enabled_did_change(value, change)
    AIOStore.write tunnels_enabled_key, value
    start_or_kill_ssh_tunnel_task
  end

  def box_state_did_change(value, change)
    start_or_kill_ssh_tunnel_task
  end

  def connected_did_change(value, change)
    start_or_kill_ssh_tunnel_task
  end

  def start_or_kill_ssh_tunnel_task
    if @ssh_tunnel_task
      if @enabled && @box.state == AIOBox::STATE_RUNNING && AIOApp.connected
        @ssh_tunnel_task.restart
      else
        @ssh_tunnel_task.kill
      end
    end
  end

  def tunnels_enabled_key
    "user:#{AIOApp.current_user.id}:box:#{@box.id}:tunnels_enabled" if @box
  end

  def local_tunnels_key
    "user:#{AIOApp.current_user.id}:box:#{@box.id}:local_tunnels" if @box
  end

  def parse_tunnels_hash_array(tunnels_array)
    tunnels_array.map do |tun|
      AIOSSHTunnel.new tun[ORIGIN_PORT_KEY]
    end if tunnels_array
  end

  def tunnel_objects_to_hash_array(tunnels)
    tunnels.map do |tunnel|
      {
        ORIGIN_PORT_KEY      => tunnel.origin_port,
        DESTINATION_HOST_KEY => tunnel.destination_host,
        DESTINATION_PORT_KEY => tunnel.destination_port
      }
    end
  end

  def tunnels_array_did_change(value, change)
    case change[NSKeyValueChangeKindKey]
      when NSKeyValueChangeInsertion, NSKeyValueChangeSetting
        observe_tunnel_items change
      when NSKeyValueChangeRemoval
        unobserve_tunnel_items change
      when NSKeyValueChangeReplacement
        unobserve_tunnel_items change
        observe_tunnel_items change
    end
    save_tunnels
    start_or_kill_ssh_tunnel_task
  end

  def observe_tunnel_items(change)
    change[NSKeyValueChangeNewKey].each do |tunnel|
      observe(tunnel, 'origin_port')      { |v,c| tunnel_item_did_change v,c }
      observe(tunnel, 'destination_host') { |v,c| tunnel_item_did_change v,c }
      observe(tunnel, 'destination_port') { |v,c| tunnel_item_did_change v,c }
    end
  end

  def unobserve_tunnel_items(change)
    change[NSKeyValueChangeOldKey].each do |tunnel|
      stop_observing tunnel, 'origin_port'
      stop_observing tunnel, 'destination_host'
      stop_observing tunnel, 'destination_port'
    end
  end

  def tunnel_item_did_change(value, change)
    save_tunnels
    start_or_kill_ssh_tunnel_task
  end
end
