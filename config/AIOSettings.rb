require 'ostruct'

info = NSBundle.mainBundle.infoDictionary

AIOSettings = OpenStruct.new

AIOSettings.env  = info['AIO_ENV']
AIOSettings.host = info['AIO_HOST']
AIOSettings.sign_up_url = info['AIO_SIGN_UP_URL']
