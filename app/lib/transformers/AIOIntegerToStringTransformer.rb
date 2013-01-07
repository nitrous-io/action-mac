class AIOIntegerToStringTransformer < NSValueTransformer
  def self.allowsReverseTransformation
    true
  end

  def transformedValue(value)
    value.to_s
  end

  def reverseTransformedValue(value)
    value.to_i
  end
end
