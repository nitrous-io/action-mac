require 'AIOCollection'
require 'AIOObserver'
require 'AIOBox'

class AIOBoxCollection < AIOCollection
  include AIOObserver

  model AIOBox
  resource_path '/boxes'
  json_root 'boxes'

  def initialize
    super
    observe(self, 'content') { |v,c| content_did_change v,c }
  end

  def finalize
    stop_observing self, 'content'
  end

  private
  def content_did_change(value, change)
    case change[NSKeyValueChangeKindKey]
      when NSKeyValueChangeInsertion
      when NSKeyValueChangeRemoval
        did_remove_box change
      when NSKeyValueChangeReplacement
        did_remove_box change
    end
  end

  def did_remove_box(change)
    change[NSKeyValueChangeOldKey].each do |removed_box|
      removed_box.state = AIOBox::STATE_REMOVED
    end
   end
end
