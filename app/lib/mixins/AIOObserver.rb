framework 'Foundation'

module AIOObserver
  def observe(target, key_path, options={}, &block)
    @_aio_observations ||= {}
    observations_for_target = @_aio_observations[target.object_id] ||= {}
    observations = observations_for_target[key_path] ||= []
    observation = { callback: block, always: options[:always] || false }
    observations << observation

    if observations.count == 1
      observing_options = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
      target.addObserver self, forKeyPath: key_path, options: observing_options, context: nil
    end

    if options[:initial]
      observeValueForKeyPath key_path, ofObject: target, change: {
        NSKeyValueChangeKindKey => NSKeyValueChangeSetting,
        NSKeyValueChangeNewKey => target.valueForKeyPath(key_path)
      }, context: nil
    end
  end

  def stop_observing(target, key_path)
    target.removeObserver self, forKeyPath: key_path
    if @_aio_observations && (observations_for_target = @_aio_observations[target.object_id])
      observations_for_target.delete key_path
    end
  end

  def observeValueForKeyPath(key_path, ofObject: target, change: change, context: context)
    if @_aio_observations && (observations_for_target = @_aio_observations[target.object_id])
      if observations = observations_for_target[key_path]
        observations.each do |observation|
          if observation[:always] || change[NSKeyValueChangeNewKey] != change[NSKeyValueChangeOldKey]
            observation[:callback].call target.valueForKeyPath(key_path), change
          end
        end
      end
    end
  end
end
