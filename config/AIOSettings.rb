require 'ostruct'

info = NSBundle.mainBundle.infoDictionary
env = info['AIOEnv']

AIOSettings = OpenStruct.new(
  env: env,
  host: info['AIOHost'],
  sign_up_url: info['AIOSignUpURL'],
  oauth_client_id: info['AIOOAuthClientID'],
  oauth_client_secret: info['AIOOAuthClientSecret'],
  keychain_service_name: info['CFBundleName'] + (env != 'production' ? " (#{env})" : ''),
  debug: env == 'development'
) unless defined?(AIOSettings)

