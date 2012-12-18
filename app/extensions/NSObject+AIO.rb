class NSObject
  def g(key_path)
    valueForKeyPath key_path
  end

  def self.dependent_property(name, dependencies)
    define_singleton_method :"keyPathsForValuesAffecting#{name.to_s.capitalize}" do
      NSSet.setWithArray dependencies
    end
  end
end
