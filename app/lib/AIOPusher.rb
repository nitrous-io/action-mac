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
      NSNotificationCenter.defaultCenter.postNotificationName name, object: self, userInfo: { data: message }
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

    NSNotificationCenter.defaultCenter.addObserver self, selector: 'aio_pusher:', name: 'aio:pusher', object: nil
    NSNotificationCenter.defaultCenter.addObserver self, selector: 'aio_box_updated:', name: 'aio:box_updated', object: nil

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
    NSNotificationCenter.defaultCenter.removeObserver self, name: 'aio:pusher', object: nil
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
  def aio_pusher(notification)
    state = notification.userInfo[:data]
    self.connected = state == 'connected'
  end

  def aio_box_updated(notification)
    if box_attrs = JSON.parse(notification.userInfo[:data])['box']
      if box = AIOApp.boxes.find_by_id(box_attrs['id'])
        box.update_attributes box_attrs
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
