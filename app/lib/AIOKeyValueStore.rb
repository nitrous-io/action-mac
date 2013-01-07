class AIOKeyValueStore
  def initialize
    @defaults = NSUserDefaults.standardUserDefaults
  end

  def read(key)
    @defaults.objectForKey(key) if key
  end

  def write(key, value)
    @defaults.setObject(value, forKey: key) if key
  end
end
