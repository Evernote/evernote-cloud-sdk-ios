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

#import "ENCredentialStore.h"
#import "ENSDKPrivate.h"

#define DEFAULTS_CREDENTIAL_STORE_KEY @"EvernoteCredentials"

@interface ENCredentialStore()

@property (nonatomic, strong) NSMutableDictionary *store;

@end

@implementation ENCredentialStore

@synthesize store = _store;

- (id)init
{
    self = [super init];
    if (self) {
        self.store = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addCredentials:(ENCredentials *)credentials
{
    // saves auth token to keychain
    BOOL saved = [credentials saveToKeychain];
    if (saved) {
        // add it to our host => credentials dict
        [self.store setObject:credentials forKey:credentials.host];
    }
}

- (ENCredentials *)credentialsForHost:(NSString *)host
{
    ENCredentials * credentials = [self.store objectForKey:host];
    if (credentials && (![credentials areValid] || [credentials authenticationToken] == nil)) {
        [self removeCredentials:credentials];
        return nil;
    }
    return credentials;
}

- (void)removeCredentials:(ENCredentials *)credentials
{
    // delete auth token from keychain
    [credentials deleteFromKeychain];
    
    // update user defaults
    [self.store removeObjectForKey:credentials.host];
}

- (void)clearAllCredentials
{
    for (ENCredentials *credentials in [self.store allValues]) {
        [credentials deleteFromKeychain];
    }
    [self.store removeAllObjects];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.store forKey:@"store"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.store = [decoder decodeObjectForKey:@"store"];
    }
    return self;
}

#pragma mark - legacy/migration

+ (ENCredentialStore *)loadCredentialsFromAppDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:DEFAULTS_CREDENTIAL_STORE_KEY];
    ENCredentialStore *store = nil;
    if (data) {
        @try {
            store = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        @catch (NSException *exception) {
            // Deal with things like NSInvalidUnarchiveOperationException
            // just return nil for situations like this, and the caller
            // can create and save a new credentials store.
            NSLog(@"Exception unarchiving ENCredentialStore: %@", exception);
        }
    }
    return store;
}
@end
