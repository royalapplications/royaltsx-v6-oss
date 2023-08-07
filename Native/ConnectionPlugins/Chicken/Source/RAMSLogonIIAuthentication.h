#import <Foundation/Foundation.h>
#import "RAMSLogonIIAuthenticationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface RAMSLogonIIAuthentication : NSObject

+ (RAMSLogonIIAuthenticationResult* _Nullable)authenticateWithGenerator:(NSData*)generator
																modulus:(NSData*)modulus
																   resp:(NSData*)resp
															   username:(NSString*)username
															   password:(NSString*)password;

@end

NS_ASSUME_NONNULL_END
