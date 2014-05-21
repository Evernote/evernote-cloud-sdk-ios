/*
 * Copyright (c) 2014 by Evernote Corporation, All rights reserved.
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

#import "ENAuthCache.h"
#import "NSDate+EDAMAdditions.h"

@interface ENAuthCacheEntry : NSObject
@property (nonatomic, strong) EDAMAuthenticationResult * authResult;
@property (nonatomic, strong) NSDate * cachedDate;
+ (ENAuthCacheEntry *)entryWithResult:(EDAMAuthenticationResult *)result;
- (BOOL)isValid;
@end

@interface ENAuthCache ()
@property (nonatomic, strong) NSMutableDictionary * linkedCache;
@property (nonatomic, strong) ENAuthCacheEntry * businessCache;
@end

@implementation ENAuthCache
- (id)init
{
    self = [super init];
    if (self) {
        self.linkedCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setAuthenticationResult:(EDAMAuthenticationResult *)result forLinkedNotebookGuid:(NSString *)guid
{
    if (!result) {
        return;
    }
    
    ENAuthCacheEntry * entry = [ENAuthCacheEntry entryWithResult:result];
    @synchronized(self) {
        self.linkedCache[guid] = entry;
    }
}

- (EDAMAuthenticationResult *)authenticationResultForLinkedNotebookGuid:(NSString *)guid
{
    EDAMAuthenticationResult * result = nil;
    @synchronized(self) {
        ENAuthCacheEntry * entry = self.linkedCache[guid];
        if (entry && ![entry isValid]) {
            // This auth result has already expired, so evict it.
            [self.linkedCache removeObjectForKey:guid];
            entry = nil;
        }
        result = entry.authResult;
    }
    return result;
}

- (void)setAuthenticationResultForBusiness:(EDAMAuthenticationResult *)result
{
    if (!result) {
        return;
    }
    ENAuthCacheEntry * entry = [ENAuthCacheEntry entryWithResult:result];
    @synchronized(self) {
        self.businessCache = entry;
    }
}

- (EDAMAuthenticationResult *)authenticationResultForBusiness
{
    EDAMAuthenticationResult * result = nil;
    @synchronized(self) {
        ENAuthCacheEntry * entry = self.businessCache;
        if (entry && ![entry isValid]) {
            // This auth result has already expired, so evict it.
            self.businessCache = nil;
        }
        result = entry.authResult;
    }
    return result;
}
@end

@implementation ENAuthCacheEntry
+ (ENAuthCacheEntry *)entryWithResult:(EDAMAuthenticationResult *)result
{
    if (!result) {
        return nil;
    }
    ENAuthCacheEntry * entry = [[ENAuthCacheEntry alloc] init];
    entry.authResult = result;
    entry.cachedDate = [NSDate date];
    return entry;
}

- (BOOL)isValid
{
    NSTimeInterval age = fabs([self.cachedDate timeIntervalSinceNow]);
    EDAMTimestamp expirationAge = ([self.authResult.expiration longLongValue] - [self.authResult.currentTime longLongValue]) / 1000;
    // we're okay if the token is within 90% of the expiration time
    if (age > (.9 * expirationAge)) {
        return NO;
    }
    return YES;
}
@end
