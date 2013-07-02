#import "AIOOAuth.h"
#import "ASIFormDataRequest.h"
#import "AIOOAuthResponse.h"

#import "AIOMacRubyHelper.h"

static NSString * const AIOOAuthScopes = @"public boxes public_keys user push web";
static NSString * const AIOOAuthAPIPathPrefix = @"/api/v0";

NSString * const AIOOAuthErrorDomain = @"AIOOAuthErrorDomain";

static NSError *AIOOAuthIncorrectLoginError,
               *AIOOAuthNoAccessTokenError,
               *AIOOAuthInvalidAccessTokenError;

@interface AIOOAuth ()

- (NSURL *)APIURL:(NSString *)path;

@end

@implementation AIOOAuth

+ (void)initialize {
  if (self == [AIOOAuth class]) {
    AIOOAuthIncorrectLoginError     = [NSError errorWithDomain:AIOOAuthErrorDomain code:AIOOAuthErrorCodeIncorrectLogin     userInfo:nil];
    AIOOAuthNoAccessTokenError      = [NSError errorWithDomain:AIOOAuthErrorDomain code:AIOOAuthErrorCodeNoAccessToken      userInfo:nil];
    AIOOAuthInvalidAccessTokenError = [NSError errorWithDomain:AIOOAuthErrorDomain code:AIOOAuthErrorCodeInvalidAccessToken userInfo:nil];
  }
}

- (id)initWithHost:(NSString *)host clientID:(NSString *)clientID clientSecret:(NSString *)clientSecret {
  self = [super init];
  if (self) {
    self.host = host;
    self.clientID = clientID;
    self.clientSecret = clientSecret;
    self.accessToken = nil;
    self.userAgent = nil;
    self.verifySSL = YES;
  }
  return self;
}

- (void)obtainAccessTokenWithUsername:(NSString *)username password:(NSString *)password
                              success:(void(^)(NSString *accessToken, AIOOAuthResponse *response))success
                              failure:(void(^)(NSError *error, AIOOAuthResponse *response))failure {
  AIO__block(success, successCallback);
  AIO__block(failure, failureCallback);

  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/token", _host]];
  __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

  request.userAgentString = _userAgent;
  request.authenticationScheme = (NSString *)kCFHTTPAuthenticationSchemeBasic;
  request.username = _clientID;
  request.password = _clientSecret;

  [request addRequestHeader:@"Accept" value:@"application/json"];

  [request addPostValue:@"password" forKey:@"grant_type"];
  [request addPostValue:username forKey:@"username"];
  [request addPostValue:password forKey:@"password"];
  [request addPostValue:AIOOAuthScopes forKey:@"scope"];

  [request setCompletionBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    self.accessToken = response.json[@"access_token"];
    AIOCallBlock(successCallback, _accessToken, response);
  }];
  [request setFailedBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    self.accessToken = nil;
    NSError *error = request.error;
    if (response.statusCode == 401) {
      error = AIOOAuthIncorrectLoginError;
    }
    AIOCallBlock(failureCallback, error, response);
  }];
  [request startAsynchronous];
}

- (NSURL *)APIURL:(NSString *)path {
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", _host, AIOOAuthAPIPathPrefix, path]];
}

- (void)request:(NSString *)verb path:(NSString *)path options:(NSDictionary *)options
        success:(void(^)(AIOOAuthResponse *response))success
        failure:(void(^)(NSError *error, AIOOAuthResponse *response))failure {
  AIO__block(success, successCallback);
  AIO__block(failure, failureCallback);

  if (!_accessToken) {
    AIOCallBlock(failureCallback, AIOOAuthNoAccessTokenError, nil);
    return;
  }

  NSURL *url = [self APIURL:path];
  verb = [verb uppercaseString];

  __block ASIHTTPRequest *request;

  if ([verb isEqualToString:@"GET"]) {
    request = [ASIHTTPRequest requestWithURL:url];
  } else {
    request = [ASIFormDataRequest requestWithURL:url];
    request.requestMethod = verb;
  }

  request.userAgentString = _userAgent;
  [request addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _accessToken]];
  [request addRequestHeader:@"Accept" value:@"application/json"];

  [request setCompletionBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    AIOCallBlock(successCallback, response);
  }];
  [request setFailedBlock:^{
    AIOOAuthResponse *response = [[AIOOAuthResponse alloc] initWithStatusCode:request.responseStatusCode data:request.responseData];
    NSError *error = request.error;
    if (response.statusCode == 401) {
      self.accessToken = nil;
      error = AIOOAuthInvalidAccessTokenError;
    }
    AIOCallBlock(failureCallback, error, response);
  }];
  [request startAsynchronous];
}

@end