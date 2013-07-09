#import <Foundation/Foundation.h>
#import <Security/Security.h>

NSData *Base64TransformStringWithFunction(NSData *inputData, SecTransformRef (*function)(CFTypeRef, CFErrorRef *));
NSData *Base64Encode(NSData *inputData);
NSData *Base64Decode(NSData *base64Data);