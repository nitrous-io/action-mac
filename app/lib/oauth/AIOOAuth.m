#import "AIOOAuth.h"
#import "ASIFormDataRequest.h"
#import "AIOOAuthResponse.h"

#import "AIOMacRubyHelper.h"

#define AIOOAuthScopes @"public boxes public_keys user push web"

@implementation AIOOAuth

@synthesize
  clientID=_clientID,
  clientSecret=_clientSecret,
  host=_host,
  userAgent=_userAgent,
  verifySSL=_verifySSL;

- (id)initWithHost:(NSString *)host clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret {
  self = [super init];
  if (self) {
    self.host = host;
    self.clientID = clientID;
    self.clientSecret = clientSecret;
    self.userAgent = nil;
    self.verifySSL = YES;
  }
  return self;
}

- (void)obtainAccessTokenWithUsername:(NSString *)username password:(NSString *)password
                              success:(void(^)(NSString *accessToken, AIOOAuthResponse *response))successCallback
                              failure:(void(^)(NSError *error, AIOOAuthResponse *response))failureCallback {
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/token", _host]];
  __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

  [request setAuthenticationScheme:(NSString *)kCFHTTPAuthenticationSchemeBasic];
  request.username = _clientID;
  request.password = _clientSecret;

  [request addPostValue:@"password" forKey:@"grant_type"];
  [request addPostValue:username forKey:@"username"];
  [request addPostValue:password forKey:@"password"];
  [request addPostValue:AIOOAuthScopes forKey:@"scope"];

  AIO__block(successCallback, success);
  AIO__block(failureCallback, failure);

  [request setCompletionBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    AIOCallBlock(success, response.json[@"access_token"], response);
  }];
  [request setFailedBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    AIOCallBlock(failure, request.error, response);
  }];
  [request startAsynchronous];
}

@end