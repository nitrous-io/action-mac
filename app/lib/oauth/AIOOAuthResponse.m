#import "AIOOAuthResponse.h"

@implementation AIOOAuthResponse

@synthesize
  statusCode=_statusCode,
  json=_json;

- (id)initWithStatusCode:(NSInteger)statusCode data:(NSData *)data {
  self = [super init];
  if (self) {
    self.statusCode = statusCode;
    self.json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
  }
  return self;
}

@end