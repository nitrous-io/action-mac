require 'spec/SpecHelper'
require 'spec/support/FakeAIOSettings'
require 'AIOAPI'
require 'oauth2'

describe AIOAPI do
  before do
    @api = AIOAPI.new
  end

  it 'initializes oauth2 client' do
    client = @api.client
    client.should.be.kind_of OAuth2::Client
    client.id.should.equal AIOSettings.oauth_client_id
    client.secret.should.equal AIOSettings.oauth_client_secret
  end

  describe '#obtain_access_token' do
    before do
      @mock = mock 'password'
      @api.client.stub(:password).and_return @mock
    end

    it 'sets the username and token instance variables using setters (for KVO)' do
      token = OAuth2::AccessToken.new @api.client, 'some_access_token'
      @mock.should.receive(:get_token).with('user', 'pass', parse: :json, scope: AIOAPI::SCOPES).and_return token
      @api.should.receive(:token=).with token
      @api.should.receive(:username=).with 'user'
      @api.obtain_access_token 'user', 'pass'
    end
  end
end
