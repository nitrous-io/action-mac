require 'SpecHelper'
require 'FakeAIOSettings'
require 'AIOAPI'
require 'oauth2'
require 'AIOBox'

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
      @api.client.stub(:password).and_return mock('password')
    end

    it 'sets the username and token instance variables using setters (for KVO)' do
      token = OAuth2::AccessToken.new @api.client, 'some_access_token'
      @api.client.password.should.receive(:get_token).with('user', 'pass', parse: :json, scope: AIOAPI::SCOPES).and_return token
      @api.should.receive(:token=).with token
      @api.should.receive(:username=).with 'user'
      @api.obtain_access_token 'user', 'pass'
    end
  end

  describe '#request' do
    context 'when token is absent' do
      before do
        @api.token = nil
      end

      it 'does nothing' do
        @api.request('get', '/boxes').should.be.nil
      end
    end

    context 'when token is present' do
      before { @api.token = mock 'token' }

      context 'when an error occurs with response code 401' do
        before do
          response = mock 'response', parsed: '', body: '', :error= => nil, status: 401
          error = OAuth2::Error.new response
          @api.token.should.receive(:request).with(:put, "#{AIOAPI::API_PATH_PREFIX}/boxes/stop", parse: :json).and_raise error
        end

        it 'destroys the invalid access token and returns nil' do
          res = @api.request :put, '/boxes/stop'
          res.should.be.nil
          @api.token.should.be.nil
        end
      end

      context 'when there is no error' do
        before do
          @response = mock 'response'
          @api.token.should.receive(:request).with(:get, "#{AIOAPI::API_PATH_PREFIX}/boxes", parse: :json).and_return @response
        end

        it 'returns the response' do
          @api.request(:get, '/boxes').should.equal @response
        end
      end
    end
  end
end
