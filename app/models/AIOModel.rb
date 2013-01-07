class AIOModel
  attr_accessor :id

  def initialize(attrs={})
    update_attributes attrs
  end

  def update_attributes(attrs={})
    attrs.each_pair do |key, value|
      setter = :"#{key}="
      if respond_to? setter
        send setter, value
      end
    end
  end

  def api
    raise NotImplementedError
  end

  def <=>(other_obj)
    id <=> other_obj.id
  end
end

class AIOModel
  def api
    AIOApp.api
  end
end if RUBY_ENGINE == 'macruby'

