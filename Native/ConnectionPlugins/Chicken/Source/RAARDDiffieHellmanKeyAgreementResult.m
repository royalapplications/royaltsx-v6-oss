#import "RAARDDiffieHellmanKeyAgreementResult.h"

@interface RAARDDiffieHellmanKeyAgreementResult ()

@property (strong, readwrite) NSData* publicKey;
@property (strong, readwrite) NSData* privateKey;
@property (strong, readwrite) NSData* secretKey;

@end

@implementation RAARDDiffieHellmanKeyAgreementResult

- (instancetype)initWithPublicKey:(NSData *)publicKey
					   privateKey:(NSData *)privateKey
						secretKey:(NSData *)secretKey {
	self = [super init];
	
	if (self) {
		self.publicKey = publicKey;
		self.privateKey = privateKey;
		self.secretKey = secretKey;
	}
	
	return self;
}

@end
