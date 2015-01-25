//
//  ENSSKeychain.m
//  ENSSKeychain
//
//  Created by Sam Soffes on 5/19/10.
//  Copyright (c) 2010-2014 Sam Soffes. All rights reserved.
//

#import "ENSSKeychain.h"

NSString *const kENSSKeychainErrorDomain = @"com.samsoffes.ENSSKeychain";
NSString *const kENSSKeychainAccountKey = @"acct";
NSString *const kENSSKeychainCreatedAtKey = @"cdat";
NSString *const kENSSKeychainClassKey = @"labl";
NSString *const kENSSKeychainDescriptionKey = @"desc";
NSString *const kENSSKeychainLabelKey = @"labl";
NSString *const kENSSKeychainLastModifiedKey = @"mdat";
NSString *const kENSSKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
	static CFTypeRef ENSSKeychainAccessibilityType = NULL;
#endif

@implementation ENSSKeychain

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account {
	return [self passwordForService:serviceName account:account error:nil];
}


+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ENSSKeychainQuery *query = [[ENSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	[query fetch:error];
	return query.password;
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account {
	return [self deletePasswordForService:serviceName account:account error:nil];
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ENSSKeychainQuery *query = [[ENSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	return [query deleteItem:error];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account {
	return [self setPassword:password forService:serviceName account:account error:nil];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	ENSSKeychainQuery *query = [[ENSSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	query.password = password;
	return [query save:error];
}


+ (NSArray *)allAccounts {
	return [self accountsForService:nil];
}


+ (NSArray *)accountsForService:(NSString *)serviceName {
	ENSSKeychainQuery *query = [[ENSSKeychainQuery alloc] init];
	query.service = serviceName;
	return [query fetchAll:nil];
}


#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
	return ENSSKeychainAccessibilityType;
}


+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
	CFRetain(accessibilityType);
	if (ENSSKeychainAccessibilityType) {
		CFRelease(ENSSKeychainAccessibilityType);
	}
	ENSSKeychainAccessibilityType = accessibilityType;
}
#endif

@end
