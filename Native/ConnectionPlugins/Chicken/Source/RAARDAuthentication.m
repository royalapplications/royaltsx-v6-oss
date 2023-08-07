#import "RAARDAuthentication.h"
#import "RAARDDiffieHellmanKeyAgreementResult.h"

#import <openssl/ssl.h>
#import <openssl/dh.h>
#import <openssl/md5.h>

@implementation RAARDAuthentication

// C array size for plaintext to be encrypted
#define CRED_ARRAY_SIZE 128

// High level overview: https://stackoverflow.com/a/7476877/1025706
// Java Implementation: https://github.com/simmons/valence/blob/f06b9f987cc6109d67b0f28f81e9ccd761f914fa/src/com/cafbit/valence/rfb/RFBSecurityARD.java
// ObjC (OpenSSL) Implementation: https://github.com/vwong2013/iOSVNCInputClient/blob/master/iOSVNCInputClient/RFB/RFBSecurityARD.m
/*
 1. Read the authentication material from the socket. A two-byte generator value, a two-byte key length value, the prime modulus (keyLength bytes), and the peer's generated public key (keyLength bytes).
 2. Generate your own Diffie-Hellman public-private key pair.
 3. Perform Diffie-Hellman key agreement, using the generator (g), prime (p), and the peer's public key. The output will be a shared secret known to both you and the peer.
 4. Perform an MD5 hash of the shared secret. This 128-bit (16-byte) value will be used as the AES key.
 5. Pack the username and password into a 128-byte plaintext "credentials" structure: { username[64], password[64] }. Null-terminate each. Fill the unused bytes with random characters so that the encryption output is less predictable.
 6. Encrypt the plaintext credentials with the 128-bit MD5 hash from step 4, using the AES 128-bit symmetric cipher in electronic codebook (ECB) mode. Use no further padding for this block cipher.
 7. Write the ciphertext from step 6 to the stream. Write your generated DH public key to the stream.
 8. Check for authentication pass/fail as usual.
 */
+ (RAARDAuthenticationResult*)authenticateWithPrime:(NSData*)prime
										  generator:(NSData*)generator
											peerKey:(NSData*)peerKey
										  keyLength:(NSInteger)keyLength
										   username:(NSString*)username
										   password:(NSString*)password {
	// 1. perform Diffie-Hellman key agreement
	RAARDDiffieHellmanKeyAgreementResult* agreementResult = [self performDiffieHellmanKeyAgreementWithPrime:prime
																								  generator:generator
																									peerKey:peerKey
																								  keyLength:keyLength];
	
	if (!agreementResult) {
		// Agreement failed
		return [RAARDAuthenticationResult emptyResult];
	}
	
	// 2. Get MD5 hash of the shared secret
	NSData* secretHash = [self md5OfData:agreementResult.secretKey];
	
	// 3. ciphertext = AES128(shared, username[64]:password[64]);
	// Fill new C array with random bytes for security
	unsigned char creds[CRED_ARRAY_SIZE];
	
	if ((SecRandomCopyBytes(kSecRandomDefault, CRED_ARRAY_SIZE, creds)) != 0) {
		return [RAARDAuthenticationResult emptyResult];
	};
	
	// Convert username and password strings into C strings
	const unsigned char* userBytes = (unsigned char *)username.UTF8String;
	const unsigned char* passBytes = (unsigned char *)password.UTF8String;
	
	// Cap length at 63 as index is 0
	unsigned int userByteLength = (unsigned int)[username lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	unsigned int passByteLength = (unsigned int)[password lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	int userLength = (userByteLength < 63) ? userByteLength : 63;
	int passLength = (passByteLength < 63) ? passByteLength : 63;
	
	// Merge username and password into single array
	memcpy(creds, userBytes, (userLength * sizeof(unsigned char)));
	memcpy(creds + (CRED_ARRAY_SIZE / 2), passBytes, (passLength * sizeof(unsigned char))); // Shift starting memory location
	
	// Add null bytes to indicate end of c string
	creds[userLength] = '\0';
	creds[(CRED_ARRAY_SIZE/2) + passLength] = '\0';
	
	NSData* credentials = [NSData dataWithBytes:creds
										 length:CRED_ARRAY_SIZE];
	
	NSData* cipherText = [self performAES128WithSecretKey:secretHash
													  for:credentials];
	
	if (cipherText == nil) {
		return [RAARDAuthenticationResult emptyResult];
	}
	
	// 4. send the ciphertext + DH public key
	RAARDAuthenticationResult* result = [[RAARDAuthenticationResult alloc] initWithCipherText:cipherText
																					publicKey:agreementResult.publicKey];
	
	return result;
}

+ (nullable RAARDDiffieHellmanKeyAgreementResult*)performDiffieHellmanKeyAgreementWithPrime:(NSData*)prime
																				  generator:(NSData*)generator
																					peerKey:(NSData*)peerKey
																				  keyLength:(NSInteger)keyLength {
	if (!prime ||
		!generator ||
		!peerKey ||
		keyLength <= 0) {
		return nil;
	}
	
	// 2. perform Diffie-Hellman key agreement
	
	// Convert C Strings into BIGNUM structs
	BIGNUM* bigPrime = NULL;
	BIGNUM* bigGenerator = NULL;
	BIGNUM* bigPeerKey = NULL;
	
	// Network received bytes should def. be in Big Endian format...
	bigPrime = BN_bin2bn(prime.bytes, (int)prime.length, NULL);
	bigGenerator = BN_bin2bn(generator.bytes, (int)generator.length, NULL);
	bigPeerKey = BN_bin2bn(peerKey.bytes, (int)peerKey.length, NULL);
	
	if (!bigPeerKey ||
		!bigGenerator ||
		!bigPrime) {
		return nil;
	}
	
	// Create DH struct
	DH* dhOwnKey;
	
	if (!(dhOwnKey = DH_new())) {
		return nil;
	}
	
	// Populate DH struct with copy of (so underlying BIGNUM's are freed in other method) required prime, generator
	DH_set0_pqg(dhOwnKey, bigPrime, nil, bigGenerator);
	
	// generate my public/private key pair using peer-supplied prime and generator
	if (!(DH_generate_key(dhOwnKey))) {
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// allocate memory for secret key and double check own generated key pair are of the right length
	unsigned char* sharedSecret;
	
	int secretLength = DH_size(dhOwnKey);
	
	if (secretLength != keyLength) {
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	if (!(sharedSecret = malloc(sizeof(unsigned char) * secretLength))) {
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// perform key agreement
	if ((DH_compute_key(sharedSecret, bigPeerKey, dhOwnKey)) == -1) { // Compute shared secret
		free(sharedSecret);
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// Copy results and free stuff
	unsigned char *privKey, *pubKey;
	
	int privKeyLength = BN_num_bytes(DH_get0_priv_key(dhOwnKey));
	int pubKeyLength = BN_num_bytes(DH_get0_pub_key(dhOwnKey));
	
	// Check key lengths of generated private and public DH keys
	if (privKeyLength != keyLength ||
		pubKeyLength != keyLength) {
		free(sharedSecret);
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// Allocate memory for private and public keys
	if (!(privKey = malloc(sizeof(unsigned char) * privKeyLength))) {
		free(sharedSecret);
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	if (!(pubKey = malloc(sizeof(unsigned char) * pubKeyLength))) {
		free(privKey);
		free(sharedSecret);
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// Convert stored priv and pub keys into big endian form
	if ((BN_bn2bin(DH_get0_priv_key(dhOwnKey), privKey)) <= 0 ||
		(BN_bn2bin(DH_get0_pub_key(dhOwnKey), pubKey)) <= 0) {
		free(privKey);
		free(pubKey);
		free(sharedSecret);
		DH_free(dhOwnKey);
		
		return nil;
	}
	
	// Duplicate string keys and free allocated pointers created in this method
	// Expect pointers to be pre-allocated with adequate memory already
	NSData* resultPublicKey = [NSData dataWithBytes:pubKey length:pubKeyLength];
	NSData* resultPrivateKey = [NSData dataWithBytes:privKey length:privKeyLength];
	NSData* resultSecretKey = [NSData dataWithBytes:sharedSecret length:secretLength];
	
	RAARDDiffieHellmanKeyAgreementResult* result = [[RAARDDiffieHellmanKeyAgreementResult alloc] initWithPublicKey:resultPublicKey
																										privateKey:resultPrivateKey
																										 secretKey:resultSecretKey];
	
	// Cleanup
	free(pubKey);
	free(privKey);
	free(sharedSecret);
	DH_free(dhOwnKey);
	
	return result;
}

+ (nullable NSData*)md5OfData:(NSData*)data {
	if (!data) {
		return nil;
	}
	
	const unsigned char* unwrappedData = data.bytes;
	
	static int8_t digestLength = 16; // digest length must be 16 bytes of output
	unsigned char digest[digestLength];
	
	if (!(MD5(unwrappedData, (unsigned long)data.length, digest))) {
		return nil;
	}
	
	NSData* md5Data = [NSData dataWithBytes:digest
									 length:digestLength];
	
	return md5Data;
}

+ (nullable NSData*)performAES128WithSecretKey:(NSData *)key for:(NSData*)text {
	if (!key ||
		!text) {
		return nil;
	}
	
	const unsigned char* secretKey = key.bytes; // symmetric
	const unsigned char* plaintext = text.bytes;
	
	// Check supplied Key is the same length as intended cipher
	const EVP_CIPHER* cipher = EVP_aes_128_ecb();
	int cipherKeyLength = EVP_CIPHER_key_length(cipher);
	
	if (key.length != cipherKeyLength) {
		return nil;
	}
	
	// Create EVP context
	EVP_CIPHER_CTX *context;
	
	if (!(context = EVP_CIPHER_CTX_new())) {
		return nil;
	}
	
	// Initialise encryption operation. No IV as using AES_128_ECB, not CBC
	if ((EVP_EncryptInit_ex(context, cipher, NULL, secretKey, NULL)) != 1) {
		EVP_CIPHER_CTX_free(context);
		
		return nil;
	}
	
	// Disable Padding
	// NOTE: If the pad parameter is zero then no padding is performed, the total amount of data encrypted or decrypted must then be a multiple of the block size or an error will occur.
	EVP_CIPHER_CTX_set_padding(context, 0);
	
	// Encrypt plaintext
	int cipherLength, finalLength;
	
	cipherLength = (int)text.length + (EVP_CIPHER_block_size(cipher) - 1); // Allow adequate room as per EVP man page
	
	unsigned char* ciphertext = malloc(sizeof(unsigned char) * cipherLength);
	
	if ((EVP_EncryptUpdate(context, ciphertext, &cipherLength, plaintext, (int)text.length)) != 1) {
		free(ciphertext);
		EVP_CIPHER_CTX_free(context);
		
		return nil;
	}
	
	// Finalise encryption
	// Shouldn't add anything as padding disabled
	if ((EVP_EncryptFinal_ex(context, ciphertext, &finalLength)) != 1) {
		free(ciphertext);
		EVP_CIPHER_CTX_free(context);
		
		return nil;
	}
	
	int cipherTextLength = finalLength + cipherLength;
	
	// NSLog(@"final_length %i, cipher_length %i", final_length, cipher_length);
	
	// Cleanup
	EVP_CIPHER_CTX_free(context);
	
	NSData* encryptedData = [NSData dataWithBytesNoCopy:ciphertext
												 length:cipherTextLength
										   freeWhenDone:YES];
	
	return encryptedData;
}

@end
