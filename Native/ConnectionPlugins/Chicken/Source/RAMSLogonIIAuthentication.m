#import "RAMSLogonIIAuthentication.h"

#import "d3des.h"

#define RA_MSLII_MAX_BITS 31

// Source: https://github.com/LibVNC/libvncserver/blob/242fda806d16f06890fb61339aa0a585443af8bb/common/crypto_included.c#L54
static int ra_mslii_encrypt_des(void* out,
								int* out_len,
								const unsigned char key[8],
								const void* in,
								const size_t in_len) {
	int eightbyteblocks = (int)(in_len / 8);
	int i;
	
	deskey((unsigned char*)key, EN0);
	
	for(i = 0; i < eightbyteblocks; ++i)
	des((unsigned char*)in + i*8, (unsigned char*)out + i*8);

	*out_len = (int)in_len;

	return 1;
}

static void ra_mslii_encrypt_d3des(unsigned char* where,
								   const int length,
								   unsigned char* key) {
	int i, j, out_len;
	
	for (i = 0; i< 8; i++) {
		where[i] ^= key[i];
	}
	
    ra_mslii_encrypt_des(where, &out_len, key, where, 8);
	
	for (i = 8; i < length; i += 8) {
		for (j = 0; j < 8; j++) {
			where[i + j] ^= where[i + j - 8];
		}
		
        ra_mslii_encrypt_des(where + i, &out_len, key, where + i, 8);
	}
}

static NSUInteger ra_mslii_data_to_long(NSData* data) {
    const uint8_t* bytes = data.bytes;
    
    NSUInteger result = 0;
    
    for (int i = 0; i < 8; i++) {
        result <<= 8;
        result += bytes[i];
    }
    
    return result;
}

static NSData* ra_mslii_long_to_data(NSUInteger number) {
    NSMutableData* data = [NSMutableData dataWithLength:8];
    
    for (int i = 0; i < 8; i++) {
        uint8_t newValue = 0xff & (number >> (8 * (7 - i)));
        uint8_t newBytes[1] = { newValue };
        
        [data replaceBytesInRange:NSMakeRange(i, 1) withBytes:newBytes];
    }
    
    return data;
}

static NSUInteger ra_mslii_random_number(uint32_t max) {
	NSUInteger num = arc4random_uniform(max) + 1;
    
    return num;
}

// Source: https://github.com/LibVNC/libvncserver/blob/master/libvncclient/rfbproto.c#L667
/* Simple 64bit big integer arithmetic implementation */
/* (x + y) % m, works even if (x + y) > 64bit */
#define ra_mslii_addM64(x,y,m) ((x+y)%m+(x+y<x?(((uint64_t)-1)%m+1)%m:0))

/* (x * y) % m */
static uint64_t ra_mslii_mulM64(uint64_t x, uint64_t y, uint64_t m) {
    uint64_t r;
    
    for (r=0;x>0;x>>=1) {
        if (x&1) r=ra_mslii_addM64(r,y,m);
        y=ra_mslii_addM64(y,y,m);
    }
    
    return r;
}

/* (x ^ y) % m */
static uint64_t ra_mslii_powM64(uint64_t b, uint64_t e, uint64_t m) {
    uint64_t r;
    
    for(r=1;e>0;e>>=1) {
        if(e&1) r=ra_mslii_mulM64(r,b,m);
        b=ra_mslii_mulM64(b,b,m);
    }
    
    return r;
}

@implementation RAMSLogonIIAuthentication

+ (RAMSLogonIIAuthenticationResult*)authenticateWithGenerator:(NSData*)generator
													  modulus:(NSData*)modulus
														 resp:(NSData*)resp
													 username:(NSString*)username
													 password:(NSString*)password {
	if (!generator ||
		!modulus ||
		!resp ||
		!username ||
		!password) {
		return [RAMSLogonIIAuthenticationResult emptyResult];
	}
	
    uint32_t maxNum = (((uint32_t)1) << RA_MSLII_MAX_BITS) - 1;
    
    NSUInteger generatorNum = ra_mslii_data_to_long(generator);
    
    if (generatorNum >= maxNum) {
        return [RAMSLogonIIAuthenticationResult emptyResult];
    }
    
	NSUInteger modulusNum = ra_mslii_data_to_long(modulus);
    
    if (modulusNum >= maxNum) {
        return [RAMSLogonIIAuthenticationResult emptyResult];
    }
	
    NSUInteger privNum = ra_mslii_random_number(maxNum);
    
    NSUInteger pubNum = ra_mslii_powM64(generatorNum,
                                        privNum,
                                        modulusNum);
    
	NSData* pubData = ra_mslii_long_to_data(pubNum);
	
	NSUInteger respNum = ra_mslii_data_to_long(resp);
    
    if (respNum >= maxNum) {
        return [RAMSLogonIIAuthenticationResult emptyResult];
    }
    
    NSUInteger key = ra_mslii_powM64(respNum,
                                     privNum,
                                     modulusNum);
	
	NSData* keyData = ra_mslii_long_to_data(key);
	
	unsigned char* keyBytes = (unsigned char*)keyData.bytes;
	
	int usernameLength = 256;
	uint8_t encryptedUsername[usernameLength];
	memset(encryptedUsername, 0, sizeof(encryptedUsername));
	
	strncpy((char*)encryptedUsername, username.UTF8String, sizeof(encryptedUsername)-1);
	ra_mslii_encrypt_d3des(encryptedUsername, (int)sizeof(encryptedUsername), keyBytes);
	
	int passwordLength = 64;
	uint8_t encryptedPassword[passwordLength];
	memset(encryptedPassword, 0, sizeof(encryptedPassword));
	
	strncpy((char*)encryptedPassword, password.UTF8String, sizeof(encryptedPassword)-1);
    ra_mslii_encrypt_d3des(encryptedPassword, (int)sizeof(encryptedPassword), keyBytes);
	
	const NSUInteger credentialsLength = usernameLength + passwordLength;
	
	NSMutableData* credentialsData = [NSMutableData dataWithCapacity:credentialsLength];
	[credentialsData appendBytes:encryptedUsername length:usernameLength];
	[credentialsData appendBytes:encryptedPassword length:passwordLength];
	
	RAMSLogonIIAuthenticationResult* result = [[RAMSLogonIIAuthenticationResult alloc] initWithPublicKey:pubData
																							 credentials:credentialsData];
	
	return result;
}

@end
