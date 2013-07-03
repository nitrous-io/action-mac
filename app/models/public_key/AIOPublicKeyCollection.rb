require 'AIOCollection'
require 'AIOPublicKey'

class AIOPublicKeyCollection < AIOCollection
  model AIOPublicKey
  resource_path '/public_keys'
  json_root 'public_keys'

  class PublicKeyAlreadyRegisteredError < StandardError; end
  class PublicKeyInvalidError < StandardError; end

  def register(public_key_data, &block)
    return unless public_key_data
    api.request(:post, resource_path, 'params' => { 'public_key[key]' => public_key_data }) do |err, response|
      json = response.json

      if err
        if response.statusCode == 422
          if json && json['errors'] && (key_errors = json['errors']['key'])
            if key_errors.include? 'already exists'
              err = PublicKeyAlreadyRegisteredError.new
            elsif key_errors.include? 'is not a valid SSH public key'
              err = PublicKeyInvalidError.new
            end
          end
        end
      else
        if response.statusCode == 201 && json && (attrs = json['public_key'])
          public_key = model.new
          public_key.update_attributes attrs
          add_object public_key
        end
      end
      block.call(err, response) if block
    end
  end
end
