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

#import <ENSDK/ENSDK.h>
#import "EDAM.h"
#import "ENNoteStoreClient.h"
#import "ENUserStoreClient.h"
#import "ENPreferencesStore.h"
#import "NSDate+EDAMAdditions.h"
#import "ENMLWriter.h"
@class ENNoteStoreClient;

@interface ENSession (Advanced)
// Indicates if your app is capable of supporting linked/business notebooks as app notebook destinations.
// Defaults to YES, as the non-advanced interface on ENSession will handle these transparently. If you're
// using the note store clients directly, either set this to NO, or be sure you test using a shared notebook as
// an app notebook.
@property (nonatomic, assign) BOOL supportsLinkedAppNotebook;

// Once authenticated, this flag will indicate whether the app notebook chosen by the user is, in fact, linked.
// (This will never be YES if you have set the flag above to NO). If so, you must take this into account:
// the primary note store will not allow you to access the notebook; instead, you must authenticate to the
// relevant linked notebook. You can find the linked notebook record by calling -listLinkedNotebooks on the
// primary note store.
@property (nonatomic, readonly) BOOL appNotebookIsLinked;

// This give access to the preferences store that the session keeps independently from NSUserDefaults, and is
// destroyed when the session unauthenticates. This should generally not be used in your application, but
// it is used by the sample UIActivity to track recently-used notebook destinations, which are of course
// session-specific. If you use it, please namespace your keys appropriately to avoid collisions.
@property (nonatomic, readonly) ENPreferencesStore * preferences;

// Retrive an appropriate note store client to perform API operations with:
// - The primary note store client is valid for all personal notebooks, and can also be used to authenticate with
//   shared notebooks.
// - The business note store client will only be non-nil if the authenticated user is a member of a business. With
//   it, you can access the business's notebooks.
// - Every linked notebook requires its own note store client instance to access.
- (ENNoteStoreClient *)primaryNoteStore;
- (ENNoteStoreClient *)businessNoteStore;
- (ENNoteStoreClient *)noteStoreForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook;

// Retrieve a note store client appropriate to a note ref or notebook object. These methods allow you to
// get a note store client based on an object you have retrieved through the nonadvanced API. Internally,
// these will call one of the above appropriate accessors for you.
- (ENNoteStoreClient *)noteStoreForNoteRef:(ENNoteRef *)noteRef;
- (ENNoteStoreClient *)noteStoreForNotebook:(ENNotebook *)notebook;
@end

@interface ENSessionFindNotesResult (Advanced)
@property (nonatomic, assign) int32_t updateSequenceNum;
@end

@interface ENNote (Advanced)
@property (nonatomic, copy) NSString * sourceUrl;
@property (nonatomic, strong) NSDictionary * edamAttributes;
@end

@interface ENNoteContent (Advanced)
+ (instancetype)noteContentWithENML:(NSString *)enml;
- (id)initWithENML:(NSString *)enml;
@end

@interface ENResource (Advanced)
@property (nonatomic, copy) NSString * sourceUrl;
- (NSData *)dataHash;
@end

@interface ENNoteRef (Advanced)
@property (nonatomic, readonly) NSString * guid;
@end

@interface  ENNotebook (Advanced)
@property (nonatomic, readonly) NSString * guid;
@end
