class AIOCollection < Array
  class << self
    def model(klass)
      @model = klass
    end

    def resource_path(path)
      @resource_path = path
    end

    def json_root(root)
      @json_root = root
    end
  end

  attr_accessor :api

  def initialize(api)
    super()
    @api = api
  end

  def find_by_id(id)
    select { |o| o.id == id }.first
  end

  def fetch
    resource_path = self.class.instance_variable_get(:@resource_path)
    json_root = self.class.instance_variable_get(:@json_root)
    model_class = self.class.instance_variable_get(:@model)

    if response = @api.request(:get, resource_path)
      model_attrs = response.parsed[json_root]
      new_ids = model_attrs.map { |o| o['id'] }
      old_ids = map(&:id)
      deleted_ids = old_ids - new_ids

      model_attrs.each do |attr|
        unless model = find_by_id(attr['id'])
          model = model_class.new
          push model
        end
        model.update_attributes attr
      end

      delete_if { |o| deleted_ids.include? o.id }
      sort!
    end
  end
end
