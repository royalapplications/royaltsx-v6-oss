//
//  ITSSKeychain.m
//  ITSSKeychain
//
//  Created by Sam Soffes on 5/19/10.
//  Copyright (c) 2010-2014 Sam Soffes. All rights reserved.
//

#import "ITSSKeychain.h"

NSString *const kITSSKeychainErrorDomain = @"com.samsoffes.ITSSKeychain";
NSString *const kITSSKeychainAccountKey = @"acct";
NSString *const kITSSKeychainCreatedAtKey = @"cdat";
NSString *const kITSSKeychainClassKey = @"labl";
NSString *const kITSSKeychainDescriptionKey = @"desc";
NSString *const kITSSKeychainLabelKey = @"labl";
NSString *const kITSSKeychainLastModifiedKey = @"mdat";
NSString *const kITSSKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
	static CFTypeRef ITSSKeychainAccessibilityType = NULL;
#endif

@implementation ITSSKeychain

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account {
	return [self passwordForService:serviceName account:account error:nil];
}


+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ITITSSKeychainQuery *query = [[ITITSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	[query fetch:error];
	return query.password;
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account {
	return [self deletePasswordForService:serviceName account:account error:nil];
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ITITSSKeychainQuery *query = [[ITITSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	return [query deleteItem:error];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account {
	return [self setPassword:password forService:serviceName account:account error:nil];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ITITSSKeychainQuery *query = [[ITITSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	query.password = password;
	return [query save:error];
}


+ (NSArray *)allAccounts {
	return [self accountsForService:nil];
}


+ (NSArray *)accountsForService:(NSString *)serviceName {
	ITITSSKeychainQuery *query = [[ITITSSKeychainQuery alloc] init];
	query.service = serviceName;
	return [query fetchAll:nil];
}


#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
	return ITSSKeychainAccessibilityType;
}


+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
	CFRetain(accessibilityType);
	if (ITSSKeychainAccessibilityType) {
		CFRelease(ITSSKeychainAccessibilityType);
	}
	ITSSKeychainAccessibilityType = accessibilityType;
}
#endif

@end
