class AIOTunnelingPreferencesViewController < NSViewController
  TAB_LOCAL_PORT_FORWARDING = 'LocalPortForwarding'

  attr_accessor :local_tunnels_array_controller
  attr_accessor :local_tunnels_table_view

  def init
    if super.initWithNibName 'TunnelingPreferencesView', bundle: nil
      setTitle 'Port Forwarding'
      self
    end
  end

  def add(sender)
    tunnel = AIOSSHTunnel.new
    @local_tunnels_array_controller.addObject tunnel
    row = @local_tunnels_array_controller.arrangedObjects.index tunnel
    @local_tunnels_table_view.editColumn 0, row: row, withEvent: nil, select: true
  end
end