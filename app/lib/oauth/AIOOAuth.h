#import <Foundation/Foundation.h>

@class AIOOAuthResponse;

extern NSString * const AIOOAuthErrorDomain;

typedef NS_ENUM(NSUInteger, AIOOAuthErrorCode) {
  AIOOAuthErrorCodeIncorrectLogin = 0,
  AIOOAuthErrorCodeNoAccessToken = 1,
  AIOOAuthErrorCodeInvalidAccessToken = 2,
  AIOOAuthErrorCodeFailedRequest = 3
};

@interface AIOOAuth : NSObject

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *clientID;
@property (nonatomic, retain) NSString *clientSecret;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSString *userAgent;
@property (nonatomic) BOOL verifySSL;

- (id)initWithHost:(NSString *)host clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret;
- (void)obtainAccessTokenWithUsername:(NSString *)username password:(NSString *)password
                              success:(void(^)(NSString *accessToken, AIOOAuthResponse *response))success
                              failure:(void(^)(NSError *error, AIOOAuthResponse *response))failure;

- (void)request:(NSString *)verb path:(NSString *)path options:(NSDictionary *)options
        success:(void(^)(AIOOAuthResponse *response))success
        failure:(void(^)(NSError *error, AIOOAuthResponse *response))failure;

@end