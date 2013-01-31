require 'AIOTask'

system 'killall -9 actionio-ssh'

class AIOSSHTunnelTask < AIOTask
  STATE_DISCONNECTED = 'disconnected'
  STATE_CONNECTING = 'connecting'
  STATE_CONNECTED = 'connected'
  STATE_ERROR = 'error'

  attr_accessor :ssh_tunnels
  attr_accessor :state, :last_error_message

  dependent_property :state_description, [:state, :last_error_message, 'ssh_tunnels.enabled']
  dependent_property :state_image,       [:state]

  def initialize(ssh_tunnels)
    super()
    self.ssh_tunnels = ssh_tunnels
    self.state = STATE_DISCONNECTED
    @should_restart = true
  end

  def finalize
    @should_restart = false
    super
  end

  def state_description
    'State: ' + case @state
      when STATE_DISCONNECTED
        @ssh_tunnels.enabled ? 'Disconnected' : 'Disabled'
      when STATE_CONNECTING
        'Connecting...'
      when STATE_CONNECTED
        'Connected'
      when STATE_ERROR
        "Error! #{@last_error_message}"
    end
  end

  def state_image
    'state-' + case @state
      when STATE_CONNECTING
        'yellow'
      when STATE_CONNECTED
        'green'
      when STATE_ERROR
        'red'
      else
        'gray'
    end
  end

  def initialize_child_process
    box = @ssh_tunnels.box

    args = [
      '-v', # verbose mode - print messages about progress
      '-N', # do not execute remote command
      '-g', # allow LAN connections
      '-o', 'TCPKeepAlive=yes', # use tcp keep alive
      '-o', 'ServerAliveInterval=60', # send keep alive packet to server every 60 sec
      '-o', 'UserKnownHostsFile=/dev/null',
      '-o', 'StrictHostKeyChecking=no', # no host key checking
      '-o', 'PreferredAuthentications=publickey', # pub key authentication only
      '-o', 'ExitOnForwardFailure=yes', # exit on forward failure
      '-c', 'blowfish-cbc', # use blowfish cipher
      '-p', box.port.to_s,
      "action@#{sanitize box.host}"
    ]

    args.concat(@ssh_tunnels.local_tunnels.map do |tun|
      if tun.origin_port && tun.destination_host && tun.destination_port
        ['-L', "#{tun.origin_port}/#{sanitize tun.destination_host}/#{tun.destination_port}"]
      end
    end.flatten.compact)

    args.concat(@ssh_tunnels.remote_tunnels.map do |tun|
      if tun.origin_port && tun.destination_host && tun.destination_port
        ['-R', "#{tun.origin_port}/#{sanitize tun.destination_host}/#{tun.destination_port}"]
      end
    end.flatten.compact)

    resource_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

    puts 'ssh ' + args.join(' ')

    AIOChildProcess.new "#{resource_path}/actionio-ssh", args
  end

  def start
    if [STATE_DISCONNECTED, STATE_ERROR].include? @state
      self.state = STATE_CONNECTING
      self.last_error_message = nil
      super
    end
  end

  def stop
    @should_restart = false
    super
  end

  def kill
    @should_restart = false
    super
    self.state = STATE_DISCONNECTED
  end

  def restart
    self.state = STATE_DISCONNECTED
    super
  end

  def child_process_did_write_to_stdout(text)
    process_output text
  end

  def child_process_did_write_to_stderr(text)
    process_output text
  end

  def child_process_did_terminate(code)
    super
    self.state = STATE_DISCONNECTED unless @state == STATE_ERROR
    schedule_restart # terminated due to error? restart.
  end

  protected
  def schedule_restart
    puts 'scheduling restart for ssh tunneling'
    Dispatch::Queue.main.after 10.0 do
      puts 'restarting ssh tunneling'
      restart if @should_restart
    end
  end

  def process_output(text)
    puts text
    case text
      when /Entering interactive session/
        self.state = STATE_CONNECTED
        self.last_error_message = nil
      when /cannot listen to port/
        self.state = STATE_ERROR
        port = text[/cannot listen to port: (\d+)/, 1]
        self.last_error_message = "Port #{port} is already in use."
      when /Could not resolve hostname/
        self.state = STATE_ERROR
        self.last_error_message = 'Could not resolve hostname.'
      when /Permission denied \(publickey\)/
        self.state = STATE_ERROR
        self.last_error_message = 'Authentication failed.'
    end if @state == STATE_CONNECTING

    case text
      when /Timeout, server/
        self.state = STATE_ERROR
        self.last_error_message = 'Connection timed out.'
      when /Killed by signal/
        self.state = STATE_ERROR
        self.last_error_message = 'Process killed.'
      when /Write failed: Broken pipe/
        self.state = STATE_ERROR
        self.last_error_message = 'Connection lost.'
    end
  end

  # just in case, to prevent arbitrary command injection
  def sanitize(name)
    name.to_s.gsub /[^a-zA-Z0-9\-\.]/, ''
  end
end
