class AIOCollection
  class << self
    def model(klass)
      @@model = klass
    end

    def resource_path(path)
      @@resource_path = path
    end

    def json_root(root)
      @@json_root = root
    end
  end

  def models
    raise NotImplementedError
  end

  def api
    raise NotImplementedError
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

  def find_by_id(id)
    models.find { |o| o.id == id }
  end

  def fetch
    if response = api.request(:get, @@resource_path)
      model_attrs = response.parsed[@@json_root]
      new_ids = model_attrs.map { |o| o['id'] }

      old_objects = models
      old_ids = old_objects.map(&:id)
      deleted_ids = old_ids - new_ids
      removed_objects = old_objects.select { |o| deleted_ids.include? o.id }

      new_objects = []

      model_attrs.each do |attr|
        unless model = find_by_id(attr['id'])
          model = @@model.new
          new_objects.push model
        end
        model.update_attributes attr
      end

      add_objects(new_objects)
      remove_objects(removed_objects)
    end
  end
end
