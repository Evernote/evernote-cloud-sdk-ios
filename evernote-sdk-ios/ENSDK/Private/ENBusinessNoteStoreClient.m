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

#import "ENBusinessNoteStoreClient.h"
#import "ENSDKPrivate.h"

@implementation ENBusinessNoteStoreClient
+ (instancetype)noteStoreClientForBusiness
{
    return [[ENBusinessNoteStoreClient alloc] init];
}

- (NSString *)noteStoreUrl
{
    NSAssert(self.delegate, @"ENBusinessNoteStoreClient delegate not set");
    return [self.delegate noteStoreUrlForBusinessStoreClient:self];
}

- (NSString *)authenticationToken
{
    NSAssert(self.delegate, @"ENBusinessNoteStoreClient delegate not set");
    return [self.delegate authenticationTokenForBusinessStoreClient:self];
}

- (void)createBusinessNotebook:(EDAMNotebook *)notebook
                       success:(void(^)(EDAMLinkedNotebook *notebook))success
                       failure:(void(^)(NSError *error))failure
{
    [self createNotebook:notebook success:^(EDAMNotebook *businessNotebook) {
        EDAMSharedNotebook *sharedNotebook = businessNotebook.sharedNotebooks[0];
        EDAMLinkedNotebook *linkedNotebook = [[EDAMLinkedNotebook alloc] init];
        [linkedNotebook setSharedNotebookGlobalId:sharedNotebook.globalId];
        [linkedNotebook setShareName:[businessNotebook name]];
        [linkedNotebook setUsername:[ENSession sharedSession].businessUser.username];
        [linkedNotebook setShardId:[ENSession sharedSession].businessUser.shardId];
        [[ENSession sharedSession].primaryNoteStore createLinkedNotebook:linkedNotebook success:^(EDAMLinkedNotebook *businessLinkedNotebook) {
            success(businessLinkedNotebook);
        } failure:^(NSError *error) {
            failure(error);
        }];
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
