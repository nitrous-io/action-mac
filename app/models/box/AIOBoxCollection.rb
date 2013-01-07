require AIO_COLLECTION_CLASS_NAME.to_s
collectionClass = Kernel.const_get AIO_COLLECTION_CLASS_NAME
require 'AIOBox'

class AIOBoxCollection < collectionClass
  model AIOBox
  resource_path '/boxes'
  json_root 'boxes'
end
