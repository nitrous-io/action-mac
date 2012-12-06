(function() {
  var self = window.aio = {
    env: null
  , bridge: null
  , userId: null
  , oAuthToken: null
  , pusherKey: null
  , pusher: null
  , channel: null

  , initialize: function() {
    if(self.env == 'development') {
      Pusher.log = function(message) {
        self.log(message);
      };
    }
    window.onerror = function(errorMsg, url, lineNumber) {
      self.log('Uncaught Error:' + errorMsg + ' ' + url + ' ' + lineNumber);
      return true;
    }
  }

  , log: function(string) {
    if(self.bridge) {
      self.bridge.log_(string);
    }
  }

  , postNotification: function(name, msg) {
    if(self.bridge) {
      if(typeof msg == 'object') {
        msg = JSON.stringify(msg);
      } else if(typeof msg == 'undefined') {
        msg = null;
      }
      self.bridge.post$_notification_message_(name, msg);
    }
  }

  , connect: function() {
      self.log('AIOPusher: connecting...');
      self.log(location.href);
      if(!self.pusher) {
        self.pusher = new Pusher(self.pusherKey, {
          encrypted: true
        , auth: {
            headers: {
              Authorization: 'Bearer ' + self.oAuthToken
            }
          }
        });

        self.pusher.connection.bind('connected', function() {
          self.postNotification('aio:pusher', 'connected');
        });

        self.pusher.connection.bind('unavailable', function() {
          self.postNotification('aio:pusher', 'unavailable');
        });

        self.pusher.connection.bind('disconnected', function() {
          self.postNotification('aio:pusher', 'disconnected');
        });

        self.subscribeToPrivateChannel();
      }
    }

  , subscribeToPrivateChannel: function() {
    var channelName = 'private-user-' + self.userId;
    self.channel = self.pusher.subscribe(channelName);

    self.channel.bind('pusher:subscription_error', function() {
      self.log('Failed to subscribe to private channel: ' + channelName + ', retrying...');
      window.setTimeout(function() {
        self.pusher.subscribe(channelName);
      }, 5000);
    });

    self.channel.bind('pusher:subscription_succeeded', function() {
      self.log('Successfully subscribed to private channel: ' + channelName + '.');
    });

    self.channel.bind('aio:box_updated', function(json) {
      self.postNotification('aio:box_updated', json);
    });
  }

  , disconnect: function() {
      self.bridge.log_('AIOPusher: disconnecting...');
      if(self.pusher) {
        self.pusher.disconnect();
      }
      self.pusher = null;
      self.channel = null;
    }
  }
}());
