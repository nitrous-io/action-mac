(function() {
  window.aio = self = {
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
        self.bridge.log_(message);
      };
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

        self.channel = self.pusher.subscribe('private-user-' + self.userId);

        self.channel.bind('aio:box_updated', function(json) {
          self.postNotification('aio:box_updated', json);
        });
      }
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
