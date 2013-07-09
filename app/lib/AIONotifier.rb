class AIONotifier
  def initialize
    if defined?(NSUserNotificationCenter) && NSUserNotificationCenter.respond_to?(:defaultUserNotificationCenter)
      @user_notification_center = NSUserNotificationCenter.defaultUserNotificationCenter
      @user_notification_center.setDelegate self
    end
  end

  def finalize
    @user_notification_center.setDelegate(nil) if @user_notification_center
  end

  def notify(title, subtitle=nil, informative_text=nil)
    if @user_notification_center && AIOStore.read('show_desktop_notifications')
      notification = NSUserNotification.new
      notification.setTitle title
      notification.setSubtitle subtitle
      notification.setInformativeText informative_text
      @user_notification_center.deliverNotification notification
    end
  end

  def userNotificationCenter(center, shouldPresentNotification: notification)
    true
  end
end
