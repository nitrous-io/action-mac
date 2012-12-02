require 'AIOModel'

class AIOBox < AIOModel
  attr_accessor :name, :state, :host, :port

  def state_description
    "State: #{@state.capitalize}"
  end

  def state_image
    'state-' + case @state
      when 'running', 'stopped', 'terminated'
        @state
      when 'suspended'
        'stopped'
      else
        'default'
    end
  end
end

# Cocoa-specific
class AIOBox
  def self.keyPathsForValuesAffectingState_description
    NSSet.setWithArray %w(state)
  end

  def self.keyPathsForValuesAffectingState_image
    NSSet.setWithArray %w(state)
  end
end if RUBY_ENGINE == 'macruby' || RUBY_ENGINE == 'rubymotion'

