#import <Foundation/Foundation.h>
#import "AIOModel.h"

@interface AIOUser : AIOModel

- (NSString *)username;
- (NSString *)email;
- (NSString *)fullName;

@end