require 'ostruct'

AIOSettings = OpenStruct.new(
  env: 'test',
  host: 'https://test.action.io',
  sign_up_url: 'https://test.action.io/users/sign_up',
  oauth_client_id: 'some_oauth_client_id',
  oauth_client_secret: 'super_secret_oauth_secret',
  keychain_service_name: 'ActionIO-test'
)
