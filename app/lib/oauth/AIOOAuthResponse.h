#import <Foundation/Foundation.h>

@interface AIOOAuthResponse : NSObject

@property (nonatomic) NSInteger statusCode;
@property (nonatomic, retain) id json;

- (id)initWithStatusCode:(NSInteger)statusCode data:(NSData *)data;

@end