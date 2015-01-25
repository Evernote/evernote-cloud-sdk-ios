/*
 * Copyright (c) 2012-2014 by Evernote Corporation, All rights reserved.
 *
 * Use of the source code and binary libraries included in this package
 * is permitted under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ENCredentials.h"
#import "ENSession.h"
#import "ENSDKPrivate.h"
#import "ENSSKeychain.h"

@interface ENCredentials()

@end

@implementation ENCredentials

@synthesize host = _host;
@synthesize edamUserId = _edamUserId;
@synthesize noteStoreUrl = _noteStoreUrl;
@synthesize webApiUrlPrefix = _webApiUrlPrefix;
@synthesize authenticationToken = _authenticationToken;
@synthesize expirationDate = _expirationDate;

- (id)initWithHost:(NSString *)host
        edamUserId:(NSString *)edamUserId
      noteStoreUrl:(NSString *)noteStoreUrl
   webApiUrlPrefix:(NSString *)webApiUrlPrefix
authenticationToken:(NSString *)authenticationToken
    expirationDate:(NSDate *)expirationDate
{
    self = [super init];
    if (self) {
        self.host = host;
        self.edamUserId = edamUserId;
        self.noteStoreUrl = noteStoreUrl;
        self.webApiUrlPrefix = webApiUrlPrefix;
        self.authenticationToken = authenticationToken;
        self.expirationDate = expirationDate;
    }
    return self;
}

- (id)initWithHost:(NSString *)host
authenticationResult:(EDAMAuthenticationResult *)authenticationResult
{
    return [self initWithHost:host
                   edamUserId:[NSString stringWithFormat:@"%d", [authenticationResult.user.id intValue]]
                 noteStoreUrl:authenticationResult.noteStoreUrl
              webApiUrlPrefix:authenticationResult.webApiUrlPrefix
          authenticationToken:authenticationResult.authenticationToken
               expirationDate:[NSDate dateWithTimeIntervalSince1970:((double)[authenticationResult.expiration longLongValue] / 1000.0f)]];
}

- (BOOL)saveToKeychain
{
    // auth token gets saved to the keychain
    NSError *error;

    ENSSKeychainQuery *query = [self keychainQuery];
    query.password = _authenticationToken;

    BOOL success = [query save:&error];
    if (!success) {
        NSLog(@"Error saving to keychain: %@ %ld", error, (long)error.code);
        return NO;
    } 
    return YES;
}

- (void)deleteFromKeychain
{
    [[self keychainQuery] deleteItem:nil];
}

- (NSString *)authenticationToken
{
    NSError *error;
    ENSSKeychainQuery* query = [self keychainQuery];
    [query fetch:&error];

    NSString *token = [query password];
    if (!token) {
        NSLog(@"Error getting password from keychain: %@", error);
    }
    return token;
}

- (BOOL)areValid
{
    // Not all credentials are guaranteed to have a valid expiration. If none is present,
    // then assume it's valid.
    if (!self.expirationDate) {
        return YES;
    }
    
    // Check the expiration date.
    if ([[NSDate date] compare:self.expirationDate] != NSOrderedAscending) {
        return NO;
    }
    
    return YES;
}

#pragma mark - ENSSKeychain Helpers

-(ENSSKeychainQuery*) keychainQuery
{
    [ENSSKeychain setAccessibilityType:kSecAttrAccessibleAlways];
    ENSSKeychainQuery *query = [[ENSSKeychainQuery alloc] init];
    query.service = self.host;
    query.account = self.edamUserId;
    if ([ENSession keychainAccessGroup]) {
        query.accessGroup = [ENSession keychainAccessGroup];
    }
    return query;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.host forKey:@"host"];
    [encoder encodeObject:self.edamUserId forKey:@"edamUserId"];
    [encoder encodeObject:self.noteStoreUrl forKey:@"noteStoreUrl"];
    [encoder encodeObject:self.webApiUrlPrefix forKey:@"webApiUrlPrefix"];
    [encoder encodeObject:self.expirationDate forKey:@"expirationDate"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.host = [decoder decodeObjectForKey:@"host"];
        self.edamUserId = [decoder decodeObjectForKey:@"edamUserId"];
        self.noteStoreUrl = [decoder decodeObjectForKey:@"noteStoreUrl"];
        self.webApiUrlPrefix = [decoder decodeObjectForKey:@"webApiUrlPrefix"];
        self.expirationDate = [decoder decodeObjectForKey:@"expirationDate"];
    }
    return self;
}

@end
