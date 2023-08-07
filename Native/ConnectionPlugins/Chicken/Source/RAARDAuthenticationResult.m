#import "RAARDAuthenticationResult.h"

@interface RAARDAuthenticationResult ()

@property (strong, readwrite, nullable) NSData* cipherText;
@property (strong, readwrite, nullable) NSData* publicKey;

@end

@implementation RAARDAuthenticationResult

- (instancetype)initWithCipherText:(NSData *)cipherText
						 publicKey:(NSData *)publicKey {
	self = [super init];
	
	if (self) {
		self.cipherText = cipherText;
		self.publicKey = publicKey;
	}
	
	return self;
}

+ (instancetype)emptyResult {
	return [[self alloc] initWithCipherText:nil publicKey:nil];
}

@end
