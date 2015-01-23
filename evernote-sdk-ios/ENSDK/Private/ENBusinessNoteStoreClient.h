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

#import "ENNoteStoreClient.h"
@class ENBusinessNoteStoreClient;

@protocol ENBusinessNoteStoreClientDelegate <NSObject>
- (NSString *)noteStoreUrlForBusinessStoreClient:(ENBusinessNoteStoreClient *)client;
- (NSString *)authenticationTokenForBusinessStoreClient:(ENBusinessNoteStoreClient *)client;
@end

@interface ENBusinessNoteStoreClient : ENNoteStoreClient
@property (nonatomic, weak) id<ENBusinessNoteStoreClientDelegate> delegate;
@property (nonatomic, copy) NSString * noteStoreUrl;
+ (instancetype)noteStoreClientForBusiness;

/** Asks the business to make a business notebook with the provided name, and the user joins the notebook.
 
 @param  notebook The desired fields for the notebook must be provided on this object. The name of the notebook must be set. If a notebook exists in the business account with the same name (via case-insensitive compare), this will throw an EDAMUserException.
 
 @param success Success completion block with the newly created Notebook. The server-side GUID will be saved in this object's 'guid' field.
 @param failure Failure completion block.
 */
- (void)createBusinessNotebook:(EDAMNotebook *)notebook
               success:(void(^)(EDAMLinkedNotebook *notebook))success
               failure:(void(^)(NSError *error))failure;

@end
