require 'ostruct'

info = NSBundle.mainBundle.infoDictionary
env = info['AIOEnv']
host = info['AIOHost']

system_version = NSDictionary.dictionaryWithContentsOfFile '/System/Library/CoreServices/SystemVersion.plist'

AIOSettings = OpenStruct.new(
  env: env,
  host: host,
  oauth_client_id: info['AIOOAuthClientID'],
  oauth_client_secret: info['AIOOAuthClientSecret'],
  keychain_service_name: info['CFBundleName'] + (env != 'production' ? " (#{env})" : ''),
  pusher_key: info['AIOPusherKey'],
  version: "v#{info['CFBundleShortVersionString']} (#{info['AIOGitHash']})",
  user_agent: "ActionIO/#{info['CFBundleShortVersionString']} (#{system_version['ProductName']}; #{system_version['ProductVersion']} #{system_version['ProductBuildVersion']}; #{NSLocale.currentLocale.localeIdentifier}) action-mac/#{info['AIOGitHash']}"
) unless defined?(AIOSettings)

