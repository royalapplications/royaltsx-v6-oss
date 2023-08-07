#import <Foundation/Foundation.h>
#import "RAARDAuthenticationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface RAARDAuthentication : NSObject

+ (RAARDAuthenticationResult* _Nullable)authenticateWithPrime:(NSData*)prime
													generator:(NSData*)generator
													  peerKey:(NSData*)peerKey
													keyLength:(NSInteger)keyLength
													 username:(NSString*)username
													 password:(NSString*)password;

@end

NS_ASSUME_NONNULL_END
