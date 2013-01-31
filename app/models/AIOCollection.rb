class AIOCollection
  class << self
    def model(klass)
      define_method(:model) { klass }
    end

    def resource_path(path)
      define_method(:resource_path) { path }
    end

    def json_root(root)
      define_method(:json_root) { root }
    end
  end

  attr_accessor :content, :last_fetch_error

  def initialize
    super
    self.content = []
  end

  def models
    mutableArrayValueForKey 'content'
  end

  def api
    AIOApp.api
  end

  def add_object(obj)
    models.push obj
  end

  def add_objects(objs)
    models.concat objs
  end

  def remove_object(obj)
    models.delete obj
  end

  def remove_objects(objs)
    models.delete_if { |o| objs.include? o }
  end

  def clear
    models.clear
  end

  def find_by_id(id)
    models.find { |o| o.id == id }
  end

  def fetch
    begin
      if response = api.request(:get, resource_path)
        model_attrs = response.parsed[json_root]
        new_ids = model_attrs.map { |o| o['id'] }

        old_objects = models
        old_ids = old_objects.map(&:id)
        deleted_ids = old_ids - new_ids
        removed_objects = old_objects.select { |o| deleted_ids.include? o.id }

        new_objects = []

        model_attrs.each do |attr|
          if obj = find_by_id(attr['id'])
            obj.update_attributes attr
          else
            new_objects.push model.new(attr)
          end
        end

        add_objects new_objects
        remove_objects removed_objects
      end
    rescue => e
      self.last_fetch_error = e
      raise e
    else
      self.last_fetch_error = nil
    end
  end
end
