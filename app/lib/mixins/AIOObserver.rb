framework 'Foundation'

module AIOObserver
  def observe(target, key_path, &block)
    @_aio_observer_callbacks ||= {}
    if ((@_aio_observer_callbacks["#{target.object_id} #{key_path}"] ||= []) << block).count == 1
      target.addObserver self, forKeyPath: key_path, options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld, context: nil
    end
  end

  def stop_observing(target, key_path)
    target.removeObserver self, forKeyPath: key_path
    @_aio_observer_callbacks.delete "#{target.object_id} #{key_path}"
  end

  def observeValueForKeyPath(key_path, ofObject: target, change: change, context: context)
    if change[NSKeyValueChangeNewKey] != change[NSKeyValueChangeOldKey]
      @_aio_observer_callbacks["#{target.object_id} #{key_path}"].each do |callback|
        callback.call target.valueForKeyPath(key_path), change
      end
    end
  end
end
