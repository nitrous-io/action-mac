require 'SpecHelper'
require 'AIOPublicKeyCollection'

describe AIOPublicKeyCollection do
  before do
    @collection = AIOPublicKeyCollection.new
    @api = mock 'api'
    @collection.stub(:api).and_return @api
  end

  describe '#register' do
    before do
      @public_key_data = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQDHCDhLX+JlcAyoIPRAbUhRQtcb/Gkr4J6dj5VEthj//UT9KeTgSgZTgtHSKswz0jQT0Xp4VmRTkIbbSp8DspQ/CxG7C7UDkIg2DiX/Pr7SavrohGCROhBu3YVj6JXtq/E= foo@bar'
    end

    context 'when the POST request returns 201 Created' do
      before do
        hash = {
          'public_key' => {
            'id' => 42,
            'name' => 'foo@bar.com',
            'md5_fingerprint' => '00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff'
          }
        }
        response = mock 'response', status: 201, parsed: hash
        @api.should.receive(:request).with(:post, '/public_keys', params: { public_key: { key: @public_key_data } }).and_return response
      end

      it 'adds the new public key to collection' do
        @collection.find_by_id(42).should.be.nil
        @collection.register @public_key_data
        public_key = @collection.find_by_id 42
        public_key.name.should.equal 'foo@bar.com'
        public_key.md5_fingerprint.should.equal '00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff'
      end
    end

    context 'when the POST request returns 422 Unprocessable Entity' do
      context 'when the response json states that the key already exists' do
        before do
          hash = {
            'errors' => {
              'key' => ['already exists']
            }
          }
          response = mock 'response', status: 422, parsed: hash, body: '', :error= => nil
          @api.should.receive(:request).with(:post, '/public_keys', params: { public_key: { key: @public_key_data } }).and_raise OAuth2::Error.new(response)
        end

        it 'raises PublicKeyAlreadyRegisteredError' do
          -> {
            @collection.register @public_key_data
          }.should.raise AIOPublicKeyCollection::PublicKeyAlreadyRegisteredError
        end
      end

      context 'when the response json states that the key is invalid' do
        before do
          hash = {
            'errors' => {
              'key' => ['is not a valid SSH public key']
            }
          }
          response = mock 'response', status: 422, parsed: hash, body: '', :error= => nil
          @api.should.receive(:request).with(:post, '/public_keys', params: { public_key: { key: @public_key_data } }).and_raise OAuth2::Error.new(response)
        end

        it 'raises PublicKeyInvalidError' do
          -> {
            @collection.register @public_key_data
          }.should.raise AIOPublicKeyCollection::PublicKeyInvalidError
        end
      end
    end
  end
end
