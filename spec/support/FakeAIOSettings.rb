require 'ostruct'

AIOSettings = OpenStruct.new(
  env: 'test',
  host: 'https://test.nitrous.io',
  sign_up_url: 'https://test.nitrous.io/users/sign_up',
  oauth_client_id: 'some_oauth_client_id',
  oauth_client_secret: 'super_secret_oauth_secret',
  keychain_service_name: 'NitrousIO-test'
)
