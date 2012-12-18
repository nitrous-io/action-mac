framework 'WebKit'
require 'AIOObserver'
require 'json'

class AIOPusher
  class Bridge
    def initialize
      # precompile
      respondsToSelector 'log:'
      respondsToSelector 'post_notification:message:'
    end

    def self.isSelectorExcludedFromWebScript(selector)
      false
    end

    def log(string)
      puts string if AIOSettings.debug
    end

    def post_notification(name, message: message)
      NSNotificationCenter.defaultCenter.postNotificationName 'AIOPusherNotification', object: self, userInfo: { name: name, message: message }
    end
  end

  include AIOObserver

  attr_accessor :ready
  attr_accessor :connected

  def initialize
    self.ready = false
    self.connected = false

    @web_view = WebView.alloc.initWithFrame NSZeroRect, frameName: nil, groupName: nil
    @bridge = Bridge.new

    NSNotificationCenter.defaultCenter.addObserver self, selector: 'pusher_did_notify:', name: 'AIOPusherNotification', object: @bridge

    @web_view.setFrameLoadDelegate self
    @web_view.mainFrame.loadHTMLString """
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset='utf-8'>
          <title></title>
          <script>window</script>
        </head>
        <body>
        </body>
      </html>
    """, baseURL: NSURL.URLWithString(AIOSettings.host + '/mac_app')
  end

  def finalize
    NSNotificationCenter.defaultCenter.removeObserver self, name: 'AIOPusherNotification', object: @bridge
  end

  def connect
    Dispatch::Queue.main.async do
      aio = eval_js 'aio'
      aio.setValue AIOApp.current_user.id, forKey: 'userId'
      aio.setValue AIOApp.api.token.token, forKey: 'oAuthToken'
      eval_js 'aio.connect()'
    end
  end

  def disconnect
    Dispatch::Queue.main.async do
      eval_js 'aio.disconnect()'
    end
  end

  def webView(sender, didClearWindowObject: window_object, forFrame: frame)
    load_js_libs
  end

  # callbacks
  def pusher_did_notify(notification)
    data = notification.userInfo
    message = data[:message]
    case data[:name]
    when 'aio:pusher'
      self.connected = (message == 'connected')
    when 'aio:box_updated'
      if box_attrs = JSON.parse(message)['box']
        if box = AIOApp.boxes.find_by_id(box_attrs['id'])
          box.update_attributes box_attrs
        end
      end
    end
  end

  private
  def eval_js(js)
    @web_view.windowScriptObject.evaluateWebScript js
  end

  def load_js_libs
    concurrent_queue do
      path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
      pusher_js = File.read "#{path}/pusher.min.js"
      aio_js = File.read "#{path}/aio.js"

      Dispatch::Queue.main.async do
        eval_js pusher_js
        eval_js aio_js

        aio = eval_js 'aio'
        aio.setValue AIOSettings.env, forKey: 'env'
        aio.setValue @bridge, forKey: 'bridge'
        aio.setValue AIOSettings.pusher_key, forKey: 'pusherKey'
        eval_js 'aio.initialize()'

        self.ready = true
      end
    end
  end
end
