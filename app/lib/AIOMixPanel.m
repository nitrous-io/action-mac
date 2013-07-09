#import "AIOMixPanel.h"
#import "AIOUser.h"
#import "ASIFormDataRequest.h"
#import "Base64.h"

static NSURL *MixPanelURL = nil;
static NSString *_token = nil;
static AIOUser *_user = nil;
static NSDictionary *DefaultProperties = nil;

@implementation AIOMixPanel

+ (void)initialize {
  MixPanelURL = [NSURL URLWithString:@"http://api.mixpanel.com/track/"];
  NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  DefaultProperties = @{
    @"os_name": systemVersion[@"ProductName"],
    @"os_version": systemVersion[@"ProductVersion"],
    @"app_name": @"NitrousIOMac",
    @"app_version": info[@"CFBundleShortVersionString"],
    @"app_git": info[@"AIOGitHash"]
  };
}

+ (void)setToken:(NSString *)token {
  _token = token;
}

+ (void)setCurrentUser:(AIOUser *)user {
  _user = user;
}

+ (void)track:(NSString *)eventName {
  [self track:eventName properties:nil];
}

+ (void)track:(NSString *)eventName properties:(NSDictionary *)properties {
  if (!_user || !_token) {
    return;
  }

  NSMutableDictionary *props = [@{
    @"username": [_user username],
    @"email": [_user email],
    @"distinct_id": [_user email],
    @"token": _token,
    @"time": @((NSInteger)[[NSDate date] timeIntervalSince1970])
  } mutableCopy];

  [props addEntriesFromDictionary:DefaultProperties];
  if(properties) {
    [props addEntriesFromDictionary:properties];
  }

  NSDictionary *dataDict = @{
    @"event": eventName,
    @"properties": props
  };

  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:NULL];
  NSString *base64Data = [[NSString alloc] initWithData:Base64Encode(jsonData) encoding:NSUTF8StringEncoding];

  ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:MixPanelURL];
  [request addPostValue:@1 forKey:@"ip"];
  [request addPostValue:base64Data forKey:@"data"];

  NSLog(@"MixPanel: %@", dataDict);
  [request startAsynchronous];
}

@end