#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RAARDAuthenticationResult : NSObject

@property (strong, readonly, nullable) NSData* cipherText;
@property (strong, readonly, nullable) NSData* publicKey;

- (instancetype)initWithCipherText:(NSData* _Nullable)cipherText
						 publicKey:(NSData* _Nullable)publicKey;

+ (instancetype)emptyResult;

@end

NS_ASSUME_NONNULL_END
