#import "Base64.h"

// https://gist.github.com/shpakovski/1902994
// updated to use garbage collection

NSData *Base64TransformStringWithFunction(NSData *inputData, SecTransformRef (*function)(CFTypeRef, CFErrorRef *)) {
  SecTransformRef transformRef = CFMakeCollectable(function(kSecBase64Encoding, NULL));
  SecTransformSetAttribute(transformRef, kSecTransformInputAttributeName, (CFTypeRef)inputData, NULL);
  CFDataRef outputDataRef = CFMakeCollectable(SecTransformExecute(transformRef, NULL));
  return (NSData *)outputDataRef;
}

NSData *Base64Encode(NSData *inputData) {
  return Base64TransformStringWithFunction(inputData, SecEncodeTransformCreate);
}

NSData *Base64Decode(NSData *base64Data) {
  return Base64TransformStringWithFunction(base64Data, SecDecodeTransformCreate);
}