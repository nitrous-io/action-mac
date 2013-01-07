require AIO_COLLECTION_CLASS_NAME.to_s
collectionClass = Kernel.const_get AIO_COLLECTION_CLASS_NAME
require 'AIOPublicKey'

class AIOPublicKeyCollection < collectionClass
  model AIOPublicKey
  resource_path '/public_keys'
  json_root 'public_keys'

  class PublicKeyAlreadyRegisteredError < StandardError; end
  class PublicKeyInvalidError < StandardError; end

  def register(public_key_data)
    return unless public_key_data
    begin
      response = api.request(:post, resource_path, params: { public_key: { key: public_key_data } })
      if response.status == 201 && (attrs = response.parsed['public_key'])
        public_key = model.new
        public_key.update_attributes attrs
        add_object public_key
      end
    rescue OAuth2::Error => e
      response = e.response
      hash = response.parsed
      if response.status == 422
        if hash['errors'] && (key_errors = hash['errors']['key'])
          if key_errors.include? 'already exists'
            raise PublicKeyAlreadyRegisteredError
          elsif key_errors.include? 'is not a valid SSH public key'
            raise PublicKeyInvalidError
          end
        end
      end
      raise e
    end
  end
end
