class AIOTunnelingPreferencesViewController < NSViewController
  TAB_LOCAL_PORT_FORWARDING = 'LocalPortForwarding'
  TAB_REMOTE_PORT_FORWARDING = 'RemotePortForwarding'

  attr_accessor :local_tunnels_array_controller, :remote_tunnels_array_controller
  attr_accessor :local_tunnels_table_view, :remote_tunnels_table_view
  attr_accessor :selected_tab_identifier

  def init
    if super.initWithNibName 'TunnelingPreferencesView', bundle: nil
      setTitle 'Tunneling'
      self.selected_tab_identifier = TAB_LOCAL_PORT_FORWARDING
      self
    end
  end

  def add(sender)
    if array_controller = selected_tunnels_array_controller
      tunnel = AIOSSHTunnel.new
      selected_tunnels_array_controller.addObject tunnel
      row = selected_tunnels_array_controller.arrangedObjects.index tunnel
      selected_table_view.editColumn 0, row: row, withEvent: nil, select: true
    end
  end

  private
  def selected_tunnels_array_controller
    case @selected_tab_identifier
    when TAB_LOCAL_PORT_FORWARDING
      @local_tunnels_array_controller
    when TAB_REMOTE_PORT_FORWARDING
      @remote_tunnels_array_controller
    end
  end

  def selected_table_view
    case @selected_tab_identifier
    when TAB_LOCAL_PORT_FORWARDING
      @local_tunnels_table_view
    when TAB_REMOTE_PORT_FORWARDING
      @remote_tunnels_table_view
    end
  end
end
