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

#import "ENSDK/ENSDK.h"
#import "ENSDKAdvanced.h"
#import "ENLinkedNotebookRef.h"
#import "ENNoteRefInternal.h"
#import "ENNoteStoreClient.h"
#import "ENUserStoreClient.h"

extern NSString * const ENBootstrapProfileNameInternational;
extern NSString * const ENBootstrapProfileNameChina;

@interface ENSession (Private)
@property (nonatomic, readonly) EDAMUserID userID;
+(NSString*) keychainAccessGroup;
@end

@interface ENNotebook (Private)
@property (nonatomic, readonly) NSString * guid;
@property (nonatomic, readonly) BOOL isLinked;
@property (nonatomic, strong) EDAMLinkedNotebook * linkedNotebook;
@property (nonatomic, assign) BOOL isDefaultNotebookOverride;
@property (nonatomic, readonly) BOOL isShared;
// For a personal notebook
- (id)initWithNotebook:(EDAMNotebook *)notebook;
// For a non-business shared notebook
- (id)initWithSharedNotebook:(EDAMSharedNotebook *)sharedNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook;
// For a publicly shared notebook
- (id)initWithPublicNotebook:(EDAMNotebook *)publicNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook;
// For a business shared notebook
- (id)initWithSharedNotebook:(EDAMSharedNotebook *)sharedNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook withBusinessNotebook:(EDAMNotebook *)notebook;
@end

@interface ENResource (Private)
+ (instancetype)resourceWithServiceResource:(EDAMResource *)serviceResource;
- (EDAMResource *)EDAMResource;
@end

@interface ENNote (Private)
- (id)initWithServiceNote:(EDAMNote *)note;
- (NSString *)content;
- (void)setGuid:(NSString *)guid;
- (void)setEnmlContent:(NSString *)enmlContent;
- (void)setResources:(NSArray *)resources;
- (EDAMNote *)EDAMNoteToReplaceServiceNoteGUID:(NSString *)guid;
- (EDAMNote *)EDAMNote;
- (BOOL)validateForLimits;
@end

@interface ENNoteContent (Private)
- (NSString *)enmlWithNote:(ENNote *)note;
@end

@interface ENNoteStoreClient (Private)
// This accessor is here to provide a declaration of the override point for subclasses that do
// nontrivial token management.
@property (nonatomic, readonly) NSString * authenticationToken;
@property (nonatomic, readonly) NSString * noteStoreUrl;

// This is how you get one of these note store objects.
+ (instancetype)noteStoreClientWithUrl:(NSString *)url authenticationToken:(NSString *)authenticationToken;

// N.B. This method is synchronous and can throw exceptions.
// Should be called only from within protected code blocks
- (EDAMAuthenticationResult *)authenticateToSharedNotebookWithGlobalId:(NSString *)globalId;

// Private pesudo-recursive method that gets all matching notes batch by batch until exhausted.
- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                         maxResults:(NSUInteger)maxResults
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(NSArray *notesMetadataList))success
                            failure:(void(^)(NSError *error))failure;
@end

@interface ENUserStoreClient (Private)
+ (instancetype)userStoreClientWithUrl:(NSString *)url authenticationToken:(NSString *)authenticationToken;

// N.B. This method is synchronous and can throw exceptions.
// Should be called only from within protected code blocks
- (EDAMAuthenticationResult *)authenticateToBusiness;
@end

@interface ENPreferencesStore (Private)
- (id)initWithStoreFilename:(NSString *)filename;
@end

// Bit twiddling macros
#define EN_FLAG_ISSET(v, f)	(!!((v) & (f)))
#define EN_FLAG_SET(v, f)	((v) |= (f))
#define EN_FLAG_CLEAR(v, f)	((v) &= (~(f)))

// Logging utility macros.
#define ENSDKLogInfo(...) \
    do { \
        [[ENSession sharedSession].logger evernoteLogInfoString:[NSString stringWithFormat:__VA_ARGS__]]; \
    } while(0);
#define ENSDKLogError(...) \
    do { \
        [[ENSession sharedSession].logger evernoteLogErrorString:[NSString stringWithFormat:__VA_ARGS__]]; \
    } while(0);

#define ENSDKResourceBundle [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"ENSDKResources" ofType:@"bundle"]]

#define ENSDKLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, nil, ENSDKResourceBundle, comment)
