// Caution: This file is linked in to Chicken project!

#import <Cocoa/Cocoa.h>
#import "ConnectionStatusArguments.h"

@protocol RoyalTsxManagedConnectionControllerProtocol <NSObject>

- (void)sessionResized;
- (void)sessionStatusChanged:(ConnectionStatusArguments*)args;

- (NSArray*)appleRemoteDesktopAuthenticationCredentials;
- (NSArray*)ultraVNCMSLogonIIAuthenticationCredentials;

@end
