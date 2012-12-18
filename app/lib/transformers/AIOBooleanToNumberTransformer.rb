class AIOBooleanToNumberTransformer < NSValueTransformer
  def self.allowsReverseTransformation
    true
  end

  def transformedValue(value)
    value == true ? 1 : 0
  end

  def reverseTransformedValue(value)
    !(value == 0)
  end
end
