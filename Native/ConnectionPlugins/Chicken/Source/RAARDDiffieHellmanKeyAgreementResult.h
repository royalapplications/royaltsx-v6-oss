#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RAARDDiffieHellmanKeyAgreementResult : NSObject

@property (strong, readonly) NSData* publicKey;
@property (strong, readonly) NSData* privateKey;
@property (strong, readonly) NSData* secretKey;

- (instancetype)initWithPublicKey:(NSData*)publicKey
					   privateKey:(NSData*)privateKey
						secretKey:(NSData*)secretKey;

@end

NS_ASSUME_NONNULL_END
