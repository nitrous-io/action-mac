class NSObject
  def g(key_path)
    valueForKeyPath key_path
  end

  def self.dependent_property(name, dependencies)
    metaclass = class << self; self; end
    metaclass.instance_eval do
      define_method :"keyPathsForValuesAffecting#{name.to_s.capitalize}" do
        NSSet.setWithArray dependencies
      end
    end
  end
end
