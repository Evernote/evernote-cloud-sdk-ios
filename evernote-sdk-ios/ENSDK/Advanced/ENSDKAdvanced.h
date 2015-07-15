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
#import "EDAM.h"
#import "ENUserStoreClient.h"
#import "ENPreferencesStore.h"
#import "NSDate+EDAMAdditions.h"
#import "ENMLWriter.h"
#import "ENNoteStoreClient.h"
#import "ENBusinessNoteStoreClient.h"
#import "ENSDKPrivate.h"

@interface ENSession (Advanced)
/**
 * Indicates if your app is capable of supporting linked/business notebooks as app notebook destinations.
 * Defaults to YES, as the non-advanced interface on ENSession will handle these transparently. If you're
 * using the note store clients directly, either set this to NO, or be sure you test using a shared notebook as
 * an app notebook.
 */
@property (nonatomic, assign) BOOL supportsLinkedAppNotebook;

/**
 * Once authenticated, this flag will indicate whether the app notebook chosen by the user is, in fact, linked.
 * (This will never be YES if you have set the flag above to NO). If so, you must take this into account:
 * the primary note store will not allow you to access the notebook; instead, you must authenticate to the
 * relevant linked notebook. You can find the linked notebook record by calling -listLinkedNotebooks on the
 * primary note store.
 */
@property (nonatomic, readonly) BOOL appNotebookIsLinked;

/**
 *  EDAMUser object of the user's personal account
 */
@property (nonatomic, strong) EDAMUser * user;

/**
 *  EDAMUser object of the user's business account
 */
@property (nonatomic, strong) EDAMUser * businessUser;

/**
 * This give access to the preferences store that the session keeps independently from NSUserDefaults, and is
 * destroyed when the session unauthenticates. This should generally not be used in your application, but
 * it is used by the sample UIActivity to track recently-used notebook destinations, which are of course
 * session-specific. If you use it, please namespace your keys appropriately to avoid collisions.
 */
@property (nonatomic, readonly) ENPreferencesStore * preferences;

/**
 *  Primary authentication token for the user, can be used to fetch personal notes and authenticate 
 *  to get shared notes and business notes
 */
@property (nonatomic, strong) NSString * primaryAuthenticationToken;

/**
 *  The user store client that manages the Evernote user account.
 */
@property (nonatomic, readonly) ENUserStoreClient * userStore;

// The following accessors all allow retrieval of an appropriate note store client to perform API operations with.

/**
 *  The primary note store client is valid for all personal notebooks, and can also be used to authenticate with
 *  shared notebooks.
 *
 *  @return A client for the user's primary note store.
 */
- (ENNoteStoreClient *)primaryNoteStore;

/**
 *  The business note store client will only be non-nil if the authenticated user is a member of a business. With
 *  it, you can access the business's notebooks.
 *
 *  @return A client for the user's business note store, or nil if the user is not a member of a business.
 */
- (ENBusinessNoteStoreClient *)businessNoteStore;

/**
 *  Every linked notebook requires its own note store client instance to access.
 *
 *  @param linkedNotebook A linked notebook record for which you'd like a note store client.
 *
 *  @return A client for the linked notebook's note store.
 */
- (ENNoteStoreClient *)noteStoreForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook;

/**
 *  Retrieves a note store client appropriate for accessing the note pointed to by the note ref.
 *  Useful for "bridging" between the high-level and EDAM APIs.
 *
 *  @param noteRef A valid note ref.
 *
 *  @return A client for the note store that contains the note ref's note.
 */
- (ENNoteStoreClient *)noteStoreForNoteRef:(ENNoteRef *)noteRef;

/**
 *  Retrieves a note store client appropriate for accessing a given notebook.
 *  Useful for "bridging" between the high-level and EDAM APIs.
 *
 *  @param notebook A valid notebook.
 *
 *  @return A client for the note store that contains the notebook.
 */
- (ENNoteStoreClient *)noteStoreForNotebook:(ENNotebook *)notebook;

/**
 *  Set to the security application group identifier, if the app should share authenticate with an application group.
 *
 *  @param the security application group identifier.
 *  @see https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html#//apple_ref/doc/uid/TP40014214-CH21-SW6
 */
+ (void) setSecurityApplicationGroupIdentifier:(NSString*)securityApplicationGroupIdentifier;

/**
 *  The keychain groups used for keychain sharing. If not set, keychain sharing is disabled.
 *
 *  This should be the shared keychain group of your app in XCode "Capabilities" > "Keychain Sharing".
 */
+ (void) setKeychainGroup:(NSString*)keychainGroup;

@end

@interface ENSessionFindNotesResult (Advanced)
/**
 *  The update sequence number (USN) associated with the current version of the note find result.
 */
@property (nonatomic, assign) int32_t updateSequenceNum;
@end

@interface ENNote (Advanced)
/**
 *  A property indicating the "source" URL for this note. Optional, and useful mainly in contexts where the 
 *  note is captured from web content.
 */
@property (nonatomic, copy) NSString * sourceUrl;

/**
 *  An optional dictionary of attributes which are used at upload time only to apply to an EDAMNote's attributes during
 *  its creation. The keys in the dictionary should be valid keys in an EDAMNoteAttributes, e.g. "author", or "sourceApplication";
 *  the values are the objects to apply. 
 *
 *  Note that downloaded notes do not populate this dictionary; if you need to inspect properties of an EDAMNote that aren't
 *  represented by ENNote, you should use ENNoteStoreClient's -getNoteWithGuid... method to download the EDAMNote directly.
 */
@property (nonatomic, strong) NSDictionary * edamAttributes;
@end

@interface ENNoteContent (Advanced)
/**
 *  Class method to create note content directly from a string of valid ENML.
 *
 *  @param enml A valid ENML string. (Invalid ENML will fail at upload time.)
 *
 *  @return A note content object.
 */
+ (instancetype)noteContentWithENML:(NSString *)enml;

/**
 *  The designated initializer for this class; initializes note content with a string of valid ENML.
 *
 *  @param enml A valid ENML string. (Invalid ENML will fail at upload time.)
 *
 *  @return A note content object.
 */
- (id)initWithENML:(NSString *)enml;

/**
 *  Return the content of the receiver in ENML format. For content created with ENML to begin with, this
 *  will simply return that ENML. For content created with other input means, the content will be transformed
 *  to ENML.
 *
 *  @return A note content object.
 */
- (NSString *)enml;
@end

@interface ENResource (Advanced)
/**
 *  A property indicating the "source" URL for this resource. Optional, and useful mainly in contexts where the
 *  resource is captured from web content.
 */
@property (nonatomic, copy) NSString * sourceUrl;

/**
 *  Accessor for the MD5 hash of the data of a resource. This is useful when writing ENML.
 *
 *  @return The hash for this resource.
 */
- (NSData *)dataHash;

/**
 *  An optional dictionary of attributes which are used at upload time only to apply to an EDAMResource's attributes during
 *  its creation. The keys in the dictionary should be valid keys in an EDAMResourceAttributes, e.g. "fileName", or "applicationData";
 *  the values are the objects to apply.
 *
 *  Note that downloaded resources do not populate this dictionary; if you need to inspect properties of an EDAMResource that aren't
 *  represented by ENResource, you should use ENNoteStoreClient's -getResourceWithGuid... method to download the EDAMResource directly.
 */
@property (nonatomic, strong) NSDictionary * edamAttributes;

/**
 *  The Evernote service guid for the resource. Valid only with a note store client
 *  that also corresponds to this resource; see ENSession to retrieve an appropriate note store client.
 */
@property (nonatomic, readonly) NSString * guid;
@end

@interface ENNoteRef (Advanced)
/**
 *  The Evernote service guid for the note that this note ref points to. Valid only with a note store client
 *  that also corresponds to this note ref; see ENSession to retrieve an appropriate note store client.
 */
@property (nonatomic, readonly) NSString * guid;
@end

@interface  ENNotebook (Advanced)
/**
 *  The Evernote service guid for the note that this notebook corresponds to. Valid only with a note store client
 *  that also corresponds to this notebook; see ENSession to retrieve an appropriate note store client.
 */
@property (nonatomic, readonly) NSString * guid;
@end

@interface ENPreferencesStore (Advanced)

+(instancetype) defaultPreferenceStore;

+(instancetype) preferenceStoreWithSecurityApplicationGroupIdentifier:(NSString*)groupId;

@end
