require 'ostruct'

info = NSBundle.mainBundle.infoDictionary
env = info['AIOEnv']
host = info['AIOHost']

AIOSettings = OpenStruct.new(
  env: env,
  host: host,
  oauth_client_id: info['AIOOAuthClientID'],
  oauth_client_secret: info['AIOOAuthClientSecret'],
  keychain_service_name: info['CFBundleName'] + (env != 'production' ? " (#{env})" : ''),
  pusher_key: info['AIOPusherKey'],
  version: "v#{info['CFBundleShortVersionString']} (#{info['AIOGitHash']})",
  debug: env == 'development'
) unless defined?(AIOSettings)

