class AIOStringToNSImageTransformer < NSValueTransformer
  def transformedValue(value)
    NSImage.imageNamed value
  end
end
