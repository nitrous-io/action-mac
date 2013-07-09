#import <Foundation/Foundation.h>

@class AIOUser;

@interface AIOMixPanel : NSObject

+ (void)setToken:(NSString *)token;
+ (void)setCurrentUser:(AIOUser *)user;
+ (void)track:(NSString *)eventName;
+ (void)track:(NSString *)eventName properties:(NSDictionary *)properties;

@end
