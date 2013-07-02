#import <Foundation/Foundation.h>

@class AIOOAuthResponse;

@interface AIOOAuth : NSObject

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *clientID;
@property (nonatomic, retain) NSString *clientSecret;
@property (nonatomic, retain) NSString *userAgent;
@property (nonatomic) BOOL verifySSL;

- (id)initWithHost:(NSString *)host clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret;
- (void)obtainAccessTokenWithUsername:(NSString *)username password:(NSString *)password
                              success:(void(^)(NSString *accessToken, AIOOAuthResponse *response))successCallback
                              failure:(void(^)(NSError *error, AIOOAuthResponse *response))failureCallback;

@end