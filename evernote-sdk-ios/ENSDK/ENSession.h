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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ENSDK.h"
#import "ENSDKLogging.h"

extern NSString * const ENSessionHostSandbox;

extern NSString * const ENSessionDidAuthenticateNotification;
extern NSString * const ENSessionDidUnauthenticateNotification;

typedef void (^ENSessionAuthenticateCompletionHandler)(NSError * authenticateError);
typedef void (^ENSessionListNotebooksCompletionHandler)(NSArray * notebooks, NSError * listNotebooksError);
typedef void (^ENSessionProgressHandler)(CGFloat progress);
typedef void (^ENSessionUploadNoteCompletionHandler)(ENNoteRef * noteRef, NSError * uploadNoteError);
typedef void (^ENSessionShareNoteCompletionHandler)(NSString * url, NSError * shareNoteError);
typedef void (^ENSessionDeleteNoteCompletionHandler)(NSError * deleteNoteError);
typedef void (^ENSessionFindNotesCompletionHandler)(NSArray * findNotesResults, NSError * findNotesError);
typedef void (^ENSessionDownloadNoteCompletionHandler)(ENNote * note, NSError * downloadNoteError);
typedef void (^ENSessionDownloadNoteThumbnailCompletionHandler)(UIImage * thumbnail, NSError * downloadNoteThumbnailError);

typedef NS_ENUM(NSInteger, ENSessionUploadPolicy) {
    ENSessionUploadPolicyCreate,            // always create a new note.
    ENSessionUploadPolicyReplace,           // replace existing note if present.
    ENSessionUploadPolicyReplaceOrCreate    // attempt to replace existing note, but if it no longer exists, create new instead.
};

typedef NS_OPTIONS(NSUInteger, ENSessionSearchScope) {
    ENSessionSearchScopeNone                = 0,      // only used if specifying an explicit notebook instead.
    ENSessionSearchScopePersonal            = 1 << 0, // search among all personal notebooks.
    ENSessionSearchScopePersonalLinked      = 1 << 1, // search among all notebooks shared to the user by others.
    ENSessionSearchScopeBusiness            = 1 << 2, // search among all business notebooks the user has joined.
    
    ENSessionSearchScopeAppNotebook         = 1 << 3  // use this if your app uses an "App Notebook". (any other set flags will be ignored.)
};
// Default search is among personal notebooks only; typical and most performant scope.
#define ENSessionSearchScopeDefault     (ENSessionSearchScopePersonal)
// Search everything this user can see. PERFORMANCE NOTE: This can be very expensive and result in many roundtrips if the
// user is a member of a business and/or has many linked notebooks.
#define ENSessionSearchScopeAll         (ENSessionSearchScopePersonal | ENSessionSearchScopePersonalLinked | ENSessionSearchScopeBusiness)

typedef NS_OPTIONS(NSUInteger, ENSessionSortOrder) {
    ENSessionSortOrderTitle                 = 1 << 0,  // case-insensitive order by title.
    ENSessionSortOrderRecentlyCreated       = 1 << 1,  // most recently created first.
    ENSessionSortOrderRecentlyUpdated       = 1 << 2,  // most recently updated first.
    ENSessionSortOrderRelevance             = 1 << 3,  // most relevant first. NB only valid when using a single search scope
    
    ENSessionSortOrderNormal                = 0 << 16, // default order (no flag)
    ENSessionSortOrderReverse               = 1 << 16  // reverse order
};
#define ENSessionSortOrderDefault       ENSessionSortOrderTitle

// Result record for findNotes call.
@interface ENSessionFindNotesResult : NSObject
@property (nonatomic, strong) ENNoteRef * noteRef;
@property (nonatomic, strong) ENNotebook * notebook;
@property (nonatomic, strong) NSNumber * updateSequenceNum;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSDate * created;
@property (nonatomic, strong) NSDate * updated;
@end

@interface ENSession : NSObject
@property (nonatomic, strong) id<ENSDKLogging> logger;
@property (nonatomic, copy) NSString * sourceApplication;  

@property (nonatomic, readonly) BOOL isAuthenticated;
@property (nonatomic, readonly) BOOL isAuthenticationInProgress;

@property (nonatomic, readonly) BOOL isPremiumUser;
@property (nonatomic, readonly) BOOL isBusinessUser;
@property (nonatomic, readonly) NSString * userDisplayName;
@property (nonatomic, readonly) NSString * businessDisplayName;

#pragma mark - Session setup

/**
 *  Set up the session object with an app consumer key and secret. This is the standard setup
 *  method. App keys are available from dev.evernote.com. You must call this method BEFORE the
 *  -sharedSession is accessed, for example in your app delegate.
 *
 *  @param key    Consumer key for your app
 *  @param secret Consumer secret for yor app
 *  @param host   (optional) If you're using a non-production host, like the developer sandbox, specify it here.
 */
+ (void)setSharedSessionConsumerKey:(NSString *)key
                     consumerSecret:(NSString *)secret
                       optionalHost:(NSString *)host;

/**
 *  Set up the session object with a developer token and Note Store URL. This is an alternate
 *  setup method used only when you are authenticating directly to your own production account. (An
 *  app for general distribution will use a consumer key and secret.) You must call this method BEFORE
 * the -sharedSession is accessed, for example in your app delegate.
 *
 *  @param token The developer token
 *  @param url   The Note Store URL.
 */
+ (void)setSharedSessionDeveloperToken:(NSString *)token
                          noteStoreUrl:(NSString *)url;

/**
 *  Access the shared session object; this is the only way to get a valid ENSession.
 *
 *  @return The shared session object.
 */
+ (ENSession *)sharedSession;

#pragma mark - Authentication

/**
 *  Authenticate a user to the Evernote service. This should be done before calling Evernote methods, if the -isAuthenticated
 *  property returns NO.
 *
 *  @param viewController A current UIViewController that an authentication view can be presented from.
 *  @param completion     A block to receive the result of the operation (an error if there was one).
 */
- (void)authenticateWithViewController:(UIViewController *)viewController
                            completion:(ENSessionAuthenticateCompletionHandler)completion;

/**
 *  Unauthenticate the current user.
 */
- (void)unauthenticate;

/**
 *  Should be called from your AppDelegate's -application:openURL:sourceApplication:annotation: to 
 *  handle authentication via app switching.
 *
 *  @param url The URL to handle.
 *
 *  @return Whether this method successfully handled this URL. (Non-Evernote URLs will return NO.)
 */
- (BOOL)handleOpenURL:(NSURL *)url;

#pragma mark - Evernote functions

/**
 *  Compile a list of all notebooks a user has access to, including personal, shared, and business
 *  notebooks as applicable.
 *
 *  @param completion A block to receive the results (a list of ENNotebook objects) or error.
 */
- (void)listNotebooksWithCompletion:(ENSessionListNotebooksCompletionHandler)completion;

/**
 *  Create a new note in Evernote by uploading a note object. 
 *  This is a simple convenience wrapper around -uploadNote:policy:toNotebook:orReplaceNote:progress:completion:
 *  which you can use for more options.
 *
 *  @param note       A prepared ENNote object, with a title, and content as resources as required.
 *  @param notebook   (optional) The notebook to create the note in. Specify nil for a default notebook.
 *  @param completion A block to receive the result of the operation (a note reference) or error.
 */
- (void)uploadNote:(ENNote *)note
          notebook:(ENNotebook *)notebook
        completion:(ENSessionUploadNoteCompletionHandler)completion;

/**
 *  Create a new note, or replace an existing note, in Evernote by uploading a note object.
 *
 *  @param note          A prepared ENNote object, with a title, and content as resources as required.
 *  @param policy        Policy indication for create vs replace, etc. See ENSessionUploadPolicy.
 *  @param notebook      (optional) The notebook to create the note in, if creating. Specify nil for a default notebook. Not valid when replace.
 *  @param noteToReplace (optional) For replace policies, the reference to the note to replace.
 *  @param progress      (optional) A block that will receive updates from 0.0 to 1.0 indicating upload progress.
 *  @param completion    A block to receive the result of the operation (a note reference) or error.
 */
- (void)uploadNote:(ENNote *)note
            policy:(ENSessionUploadPolicy)policy
        toNotebook:(ENNotebook *)notebook
     orReplaceNote:(ENNoteRef *)noteToReplace
          progress:(ENSessionProgressHandler)progress
        completion:(ENSessionUploadNoteCompletionHandler)completion;

/**
 *  Share an existing note, and creates a URL that allows access to it directly.
 *  NOTE: An application may only turn on sharing for a note when the user explicitly chooses to do so - 
 *  for example by tapping a "share" button. You may never enable sharing without the user's
 *  explicit consent.
 *
 *  @param noteRef    A reference to the note to share.
 *  @param completion (optional) A block to recieve the result of the operation (a URL) or error.
 */
- (void)shareNote:(ENNoteRef *)noteRef
       completion:(ENSessionShareNoteCompletionHandler)completion;

/**
 *  Put an existing note in the user's trash. This does not permanently expunge the note.
 *
 *  @param noteRef    A reference to the note to delete.
 *  @param completion (optional) A block to recieve an error if the operation fails.
 */
- (void)deleteNote:(ENNoteRef *)noteRef
        completion:(ENSessionDeleteNoteCompletionHandler)completion;

/**
 *  Find notes, based on given criteria, within the notebooks that the user has access to. This method results
 *  in a list of items, including note references and several useful metadata fields. (The full content of the
 *  notes can be downloaded using -downloadNote:progress:completion:)
 *
 *  @param noteSearch (optional) An ENNoteSeach object that represents a query. If this is omitted, the method will return all notes; you should probably only omit this if you specify a notebook.
 *  @param notebook   (optional) A notebook (ENNotebook) object to find within. If this is omitted, all available notebooks will be searched.
 *  @param scope      A bitflag set indicating where the method should direct its search.
 *  @param sortOrder  A bitflag set indicating how the results should be sorted.
 *  @param maxResults The maximum number of results to return. Use zero (0) here to find all results.
 *  @param completion A block to receive the result of the operation (a list of result object) or error.
 */
- (void)findNotesWithSearch:(ENNoteSearch *)noteSearch
                 inNotebook:(ENNotebook *)notebook
                    orScope:(ENSessionSearchScope)scope
                  sortOrder:(ENSessionSortOrder)sortOrder
                 maxResults:(NSUInteger)maxResults
                 completion:(ENSessionFindNotesCompletionHandler)completion;

/**
 *  Download the full content and resources of a specified note.
 *
 *  @param noteRef    A reference to the note to download.
 *  @param progress   (optional) A block that will receive updates from 0.0 to 1.0 indicating download progress.
 *  @param completion A block to receive the result of the operation (an ENNote object) or error.
 */
- (void)downloadNote:(ENNoteRef *)noteRef
            progress:(ENSessionProgressHandler)progress
          completion:(ENSessionDownloadNoteCompletionHandler)completion;

/**
 *  Download the service-generated thumbnail image for a note.
 *
 *  @param noteRef      A reference to the note for which to download the thumbnail.
 *  @param maxDimension The maximum one-side dimension of the thumbnail to download. The resulting image may be smaller than this, but will not be larger.
 *  @param completion   A block to receive the result of the operation (a UIImage object) or error.
 */
- (void)downloadThumbnailForNote:(ENNoteRef *)noteRef
                    maxDimension:(NSUInteger)maxDimension
                      completion:(ENSessionDownloadNoteThumbnailCompletionHandler)completion;
@end
