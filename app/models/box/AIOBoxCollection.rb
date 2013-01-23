require 'AIOCollection'
require 'AIOBox'

class AIOBoxCollection < AIOCollection
  model AIOBox
  resource_path '/boxes'
  json_root 'boxes'
end
