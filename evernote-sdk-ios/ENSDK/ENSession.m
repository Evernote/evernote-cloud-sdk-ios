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

#import "ENSDKPrivate.h"
#import "ENSDKAdvanced.h"
#import "ENAuthCache.h"
#import "ENNoteStoreClient.h"
#import "ENLinkedNoteStoreClient.h"
#import "ENBusinessNoteStoreClient.h"
#import "ENUserStoreClient.h"
#import "ENCredentialStore.h"
#import "ENOAuthAuthenticator.h"
#import "ENPreferencesStore.h"
#import "NSDate+EDAMAdditions.h"
#import "NSString+URLEncoding.h"
#import "ENShareURLHelper.h"
#import "ENCommonUtils.h"

// Strings visible publicly.
NSString * const ENSessionHostSandbox = @"sandbox.evernote.com";
NSString * const ENSessionDidAuthenticateNotification = @"ENSessionDidAuthenticateNotification";
NSString * const ENSessionDidUnauthenticateNotification = @"ENSessionDidUnauthenticateNotification";

// Constants valid only in this file.
static NSString * ENSessionBootstrapServerBaseURLStringCN  = @"app.yinxiang.com";
static NSString * ENSessionBootstrapServerBaseURLStringUS  = @"www.evernote.com";

static NSString * ENSessionPreferencesCredentialStore = @"CredentialStore";
static NSString * ENSessionPreferencesCurrentProfileName = @"CurrentProfileName";
static NSString * ENSessionPreferencesUser = @"User";
static NSString * ENSessionPreferencesBusinessUser = @"BusinessUser";
static NSString * ENSessionPreferencesAppNotebookIsLinked = @"AppNotebookIsLinked";
static NSString * ENSessionPreferencesLinkedAppNotebook = @"LinkedAppNotebook";
static NSString * ENSessionPreferencesSharedAppNotebook = @"SharedAppNotebook";

static NSUInteger ENSessionNotebooksCacheValidity = (5 * 60);   // 5 minutes

@interface ENSessionDefaultLogger : NSObject <ENSDKLogging>
@end

@interface ENSessionListNotebooksContext : NSObject
@property (nonatomic, strong) NSMutableArray * resultNotebooks;
@property (nonatomic, strong) NSMutableArray * linkedPersonalNotebooks;
@property (nonatomic, strong) NSMutableDictionary * sharedBusinessNotebooks;
@property (nonatomic, strong) NSCountedSet * sharedBusinessNotebookGuids;
@property (nonatomic, strong) NSMutableDictionary * businessNotebooks;
@property (nonatomic, strong) NSMutableDictionary * sharedNotebooks;
@property (nonatomic, assign) NSInteger pendingSharedNotebooks;
@property (nonatomic, strong) NSError * error;
@property (nonatomic, copy) ENSessionListNotebooksCompletionHandler completion;
@end

@interface ENSessionUploadNoteContext : NSObject
@property (nonatomic, strong) EDAMNote * note;
@property (nonatomic, strong) ENNoteRef * refToReplace;
@property (nonatomic, strong) ENNotebook * notebook;
@property (nonatomic, assign) ENSessionUploadPolicy policy;
@property (nonatomic, copy) ENSessionUploadNoteCompletionHandler completion;
@property (nonatomic, copy) ENSessionProgressHandler progress;
@property (nonatomic, strong) ENNoteStoreClient * noteStore;
@property (nonatomic, strong) ENNoteRef * noteRef;
@end

@interface ENSessionFindNotesContext : NSObject
@property (nonatomic, strong) ENNotebook * scopeNotebook;
@property (nonatomic, assign) ENSessionSearchScope scope;
@property (nonatomic, assign) ENSessionSortOrder sortOrder;
@property (nonatomic, strong) EDAMNoteFilter * noteFilter;
@property (nonatomic, strong) EDAMNotesMetadataResultSpec * resultSpec;
@property (nonatomic, assign) NSUInteger maxResults;
@property (nonatomic, assign) BOOL requiresLocalMerge;
@property (nonatomic, assign) BOOL sortAscending;
@property (nonatomic, strong) NSArray * allNotebooks;
@property (nonatomic, strong) NSMutableArray * linkedNotebooksToSearch;
@property (nonatomic, strong) NSMutableArray * findMetadataResults;
@property (nonatomic, strong) NSSet * resultGuidsFromBusiness;
@property (nonatomic, strong) NSArray * results;
@property (nonatomic, copy) ENSessionFindNotesCompletionHandler completion;
@end

@interface ENSessionFindNotesResult ()
@property (nonatomic, assign) int32_t updateSequenceNum;
@end

@interface ENSession () <ENLinkedNoteStoreClientDelegate, ENBusinessNoteStoreClientDelegate, ENOAuthAuthenticatorDelegate>
@property (nonatomic, assign) BOOL supportsLinkedAppNotebook;
@property (nonatomic, strong) ENOAuthAuthenticator * authenticator;
@property (nonatomic, copy) ENSessionAuthenticateCompletionHandler authenticationCompletion;

@property (nonatomic, copy) NSString * sessionHost;
@property (nonatomic, assign) BOOL isAuthenticated;
@property (nonatomic, strong) EDAMUser * user;
@property (nonatomic, strong) EDAMUser * businessUser;
@property (nonatomic, strong) ENPreferencesStore * preferences;
@property (nonatomic, strong) NSString * primaryAuthenticationToken;
@property (nonatomic, strong) ENUserStoreClient * userStore;
@property (nonatomic, strong) ENNoteStoreClient * primaryNoteStore;
@property (nonatomic, strong) ENBusinessNoteStoreClient * businessNoteStore;
@property (nonatomic, strong) ENAuthCache * authCache;
@property (nonatomic, strong) NSArray * notebooksCache;
@property (nonatomic, strong) NSDate * notebooksCacheDate;
@property (nonatomic, strong) dispatch_queue_t thumbnailQueue;

@property (nonatomic, strong) ENUserStoreClient * userStorePendingRevocation;

@property (nonatomic, assign) long long personalUploadUsage;
@property (nonatomic, assign) long long personalUploadLimit;
@property (nonatomic, assign) long long businessUploadUsage;
@property (nonatomic, assign) long long businessUploadLimit;

@end

@implementation ENSession

static NSString * SessionHostOverride;
static NSString * ConsumerKey, * ConsumerSecret;
static NSString * DeveloperToken, * NoteStoreUrl;
static NSString * SecurityApplicationGroupIdentifier;
static NSString * _keychainGroup, * _keychainAccessGroup;
static BOOL disableRefreshingNotebooksCacheOnLaunch;

+ (void)setSharedSessionConsumerKey:(NSString *)key
                     consumerSecret:(NSString *)secret
                       optionalHost:(NSString *)host
{
    ConsumerKey = key;
    ConsumerSecret = secret;
    SessionHostOverride = host;
    
    DeveloperToken = nil;
    NoteStoreUrl = nil;
}

+ (void)setSharedSessionDeveloperToken:(NSString *)token
                          noteStoreUrl:(NSString *)url
{
    DeveloperToken = token;
    NoteStoreUrl = url;

    ConsumerKey = nil;
    ConsumerSecret = nil;
}

+ (ENSession *)sharedSession
{
    static ENSession * session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [[ENSession alloc] init];
    });
    return session;
}

+ (void)setDisableRefreshingNotebooksCacheOnLaunch:(BOOL)disable
{
    disableRefreshingNotebooksCacheOnLaunch = disable;
}

+ (void) setSecurityApplicationGroupIdentifier:(NSString*)securityApplicationGroupIdentifier
{
    SecurityApplicationGroupIdentifier = securityApplicationGroupIdentifier;
}

+ (void) setKeychainGroup:(NSString*)keychainGroup
{
    _keychainGroup = keychainGroup;
    _keychainAccessGroup = [[[self bundleSeedID] stringByAppendingString:@"."] stringByAppendingString:_keychainGroup];
}

+ (NSString*) keychainAccessGroup
{
    return _keychainAccessGroup;
}

+ (BOOL)checkSharedSessionSettings
{
    if (DeveloperToken && NoteStoreUrl) {
        return YES;
    }
    
    if (ConsumerKey && ![ConsumerKey isEqualToString:@"your key"] &&
        ConsumerSecret && ![ConsumerSecret isEqualToString:@"your secret"]) {
        return YES;
    }
    
    NSString * error = @"Cannot create shared Evernote session without either a valid consumer key/secret pair, or a developer token set";
    // Use NSLog and not the session logger here, or we'll deadlock since we're still creating the session.
    NSLog(@"%@", error);
    [NSException raise:NSInvalidArgumentException format:@"%@", error];
    return NO;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Check to see if the app's setup parameters are set and look reasonable.
        // If this test fails, we'll essentially set a singleton to nil and never be able
        // to fix it, which is the desired development-time behavior.
        if (![[self class] checkSharedSessionSettings]) {
            return nil;
        }
        // Default to supporting linked notebooks for app notebook. Developer can toggle this off
        // if they're using advanced features and don't want to deal with the added complexity.
        self.supportsLinkedAppNotebook = YES;
        [self startup];
    }
    return self;
}

// NB: This object is a singleton, -dealloc will never be called. Here for clarity only.
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startup
{
    self.logger = [[ENSessionDefaultLogger alloc] init];
    self.preferences = SecurityApplicationGroupIdentifier ? [ENPreferencesStore preferenceStoreWithSecurityApplicationGroupIdentifier:SecurityApplicationGroupIdentifier] : [ENPreferencesStore defaultPreferenceStore];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeClientFailedAuthentication:)
                                                 name:ENStoreClientDidFailWithAuthenticationErrorNotification
                                               object:nil];
    
    self.thumbnailQueue = dispatch_queue_create("evernote-sdk-ios-thumbnail", DISPATCH_QUEUE_CONCURRENT);
    
    // Determine the host to use for this session.
    [self selectInitialSessionHost];
    
    // If the developer token is set, then we can short circuit the entire auth flow and just call ourselves authenticated.
    if (DeveloperToken) {
        self.isAuthenticated = YES;
        self.primaryAuthenticationToken = DeveloperToken;
        [self performPostAuthentication];
        return;
    }
    
    // We'll restore an existing session if there was one. Check to see if we have valid
    // primary credentials stashed away already.
    ENCredentials * credentials = [self credentialsForHost:self.sessionHost];
    if (!credentials || ![credentials areValid]) {
        self.isAuthenticated = NO;
        [self.preferences removeAllItems];
        return;
    }
    
    self.isAuthenticated = YES;
    self.primaryAuthenticationToken = credentials.authenticationToken;
    
    // We appear to have valid personal credentials, so populate the user object from cache
    self.user = [self.preferences decodedObjectForKey:ENSessionPreferencesUser];
    self.businessUser = [self.preferences decodedObjectForKey:ENSessionPreferencesBusinessUser];
    
    [self performPostAuthentication];
}

- (void)selectInitialSessionHost
{
    if (SessionHostOverride.length > 0) {
        // Use the override given by the developer. This is optional, and
        // generally used for the sandbox.
        self.sessionHost = SessionHostOverride;
    } else if (NoteStoreUrl) {
        // If we have a developer key, just get the host from the note store url.
        NSURL * noteStoreUrl = [NSURL URLWithString:NoteStoreUrl];
        self.sessionHost = noteStoreUrl.host;
    } else if ([[self currentProfileName] isEqualToString:ENBootstrapProfileNameInternational]) {
        self.sessionHost = ENSessionBootstrapServerBaseURLStringUS;
    } else if ([[self currentProfileName] isEqualToString:ENBootstrapProfileNameChina]) {
        self.sessionHost = ENSessionBootstrapServerBaseURLStringCN;
    } else {
        // Choose the initial host based on locale. Simplified Chinese locales get the yinxiang service.
        NSString * locale = [[[NSLocale currentLocale] localeIdentifier] lowercaseString];
        if ([locale hasPrefix:@"zh_hans"] || [locale isEqualToString:@"zh_cn"] || [locale isEqualToString:@"zh"]) {
            self.sessionHost = ENSessionBootstrapServerBaseURLStringCN;
        } else {
            self.sessionHost = ENSessionBootstrapServerBaseURLStringUS;
        }
    }
}

- (void)authenticateWithViewController:(UIViewController *)viewController
                    preferRegistration:(BOOL)preferRegistration
                            completion:(ENSessionAuthenticateCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
    
    // Authenticate is idempotent; check if we're already authenticated
    if (self.isAuthenticated) {
        completion(nil);
        return;
    }

    // What if we're already mid-authenticating? If we have an authenticator object already, then
    // don't stomp on it.
    if (self.authenticator) {
        ENSDKLogInfo(@"Cannot restart authentication while it is still in progress.");
        completion([NSError errorWithDomain:ENErrorDomain code:ENErrorCodeUnknown userInfo:nil]);
        return;
    }

    self.user = nil;
    self.authenticationCompletion = completion;
    
    // If the developer token is set, then we can short circuit the entire auth flow and just call ourselves authenticated.
    if (DeveloperToken) {
        self.isAuthenticated = YES;
        self.primaryAuthenticationToken = DeveloperToken;
        [self performPostAuthentication];
        return;
    }
    
    self.authenticator = [[ENOAuthAuthenticator alloc] init];
    self.authenticator.delegate = self;
    self.authenticator.consumerKey = ConsumerKey;
    self.authenticator.consumerSecret = ConsumerSecret;
    self.authenticator.host = self.sessionHost;
    self.authenticator.supportsLinkedAppNotebook = self.supportsLinkedAppNotebook;
    self.authenticator.preferRegistration = preferRegistration;
    
    // If we're overriding the standard host, then we're in some sort of development environment
    // (sandbox), and the cross-app auth won't work. In this case, force the authenticator to use
    // web auth only.
    self.authenticator.useWebAuthenticationOnly = (SessionHostOverride != nil);
    
    [self.authenticator authenticateWithViewController:viewController];
}

- (void)performPostAuthentication
{
    // We only get here after newly setting up a authenticated state, so send a notification.
    [self notifyAuthenticationChanged];
    
    // During an initial authentication, a failure in getUser or authenticateToBusiness is considered fatal.
    // But when refreshing a session, eg on app restart, we don't want to sign out users just for network
    // errors, or transient problems.
    BOOL failuresAreFatal = (self.authenticationCompletion != nil);

    __weak typeof(self) weakSelf = self;
    [[self userStore] getUserWithSuccess:^(EDAMUser * user) {
        __strong typeof(weakSelf) self = weakSelf;
        self.user = user;
        [self.preferences encodeObject:user forKey:ENSessionPreferencesUser];
        [self completeAuthenticationWithError:nil];
        
        if (!disableRefreshingNotebooksCacheOnLaunch) {
            // refresh the notebook cache
            [self listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
                if (listNotebooksError) {
                    ENSDKLogError(@"Error when listing notebooks: %@", listNotebooksError);
                }
                ENSDKLogInfo(@"Notebooks: %@", notebooks);
            }];
        }
        
        [self refreshUploadUsage];
    } failure:^(NSError * getUserError) {
        ENSDKLogError(@"Failed to get user info for user: %@", getUserError);
        [weakSelf completeAuthenticationWithError:(failuresAreFatal ? getUserError : nil)];
    }];
}

- (void)refreshUploadUsage {
    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore getSyncStateWithSuccess:^(EDAMSyncState *syncState) {
        __strong typeof(weakSelf) self = weakSelf;
        self.personalUploadUsage = syncState.uploaded.longLongValue;
        self.personalUploadLimit = self.user.accounting.uploadLimit.longLongValue;
    } failure:^(NSError *error) {
        ENSDKLogError(@"Failed to get personal sync state");
    }];
    if (self.isBusinessUser) {
        [self.businessNoteStore getSyncStateWithSuccess:^(EDAMSyncState *syncState) {
            __strong typeof(weakSelf) self = weakSelf;
            self.businessUploadUsage = syncState.uploaded.longLongValue;
            self.businessUploadLimit = self.businessUser.accounting.uploadLimit.longLongValue;
        } failure:^(NSError *error) {
            ENSDKLogError(@"Failed to get business sync state");
        }];
    }
}

- (void)completeAuthenticationWithError:(NSError *)error
{
    if (error) {
        [self unauthenticate];
    }
    if (self.authenticationCompletion) {
        self.authenticationCompletion(error);
        self.authenticationCompletion = nil;
    }
    self.authenticator = nil;
}

- (BOOL)isAuthenticationInProgress
{
    return self.authenticator != nil;
}

- (BOOL)isPremiumUser
{
    return [self.user.privilege intValue] >= PrivilegeLevel_PREMIUM;
}

- (BOOL)isBusinessUser
{
    return self.user.accounting.businessId != nil;
}

- (NSString *)userDisplayName
{
    NSString * name = self.user.name ?: self.user.username;
    return name ?: @"";
}

- (NSString *)businessDisplayName
{
    if ([self isBusinessUser]) {
        return self.user.accounting.businessName;
    }
    return nil;
}

- (NSString *)sourceApplication
{
    if (!_sourceApplication) {
        return [[NSBundle mainBundle] bundleIdentifier];
    }
    return _sourceApplication;
}

- (EDAMUserID)userID
{
    return [self.user.id intValue];
}

- (BOOL)appNotebookIsLinked
{
    return [[self.preferences objectForKey:ENSessionPreferencesAppNotebookIsLinked] boolValue];
}

// N.B. This method (currently) isn't protected against executing when API calls are currently inflight.
// Unauthenticating while operations are pending may result in undefined behavior.
- (void)unauthenticate
{
    ENSDKLogInfo(@"ENSession is unauthenticating.");

    // Revoke the primary auth token, so the app session will not appear any longer on the user's
    // security page. This is purely opportunistic, of course, hence ignoring the result.
    // Note also that this is asynchronous, but the rest of this method gets rid of all the session state,
    // so keep the user store around long enough to see it through, but keep it separate from the
    // normal session state.
    if (self.isAuthenticated) {
        self.userStorePendingRevocation = self.userStore;
        __weak typeof(self) weakSelf = self;
        [self.userStorePendingRevocation revokeLongSessionWithAuthenticationToken:self.primaryAuthenticationToken success:^{
            weakSelf.userStorePendingRevocation = nil;
        } failure:^(NSError *error) {
            weakSelf.userStorePendingRevocation = nil;
        }];
    }
    
    self.isAuthenticated = NO;
    self.user = nil;
    self.primaryAuthenticationToken = nil;
    self.userStore = nil;
    self.primaryNoteStore = nil;
    self.businessNoteStore = nil;
    self.authCache = [[ENAuthCache alloc] init];
    self.notebooksCache = nil;
    self.notebooksCacheDate = nil;
    
    // Manually clear credentials. This ensures they're removed from the keychain also.
    ENCredentialStore * credentialStore = [self credentialStore];
    [credentialStore clearAllCredentials];
    [self saveCredentialStore:credentialStore];
    
    [self.preferences removeAllItems];
    [self selectInitialSessionHost];
    
    [self notifyAuthenticationChanged];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    if (self.authenticator) {
        return [self.authenticator handleOpenURL:url];
    }
    return NO;
}

#pragma mark - listNotebooks

// Notes on the flow of this process, because it's somewhat byzantine:
// 1. Get all of the user's personal notebooks.
// 2. Get all of the user's linked notebooks. These will include business and/or shared notebooks.
// 3. If the user is a business user:
//   a. Get the business's shared notebooks. Some of these may match to personal linked notebooks.
//   b. Get the business's linked notebooks. Some of these will match to shared notebooks in (a), providing a
//      complete authorization story for the notebook.
// 4. For any remaining linked nonbusiness notebooks, auth to each and get authorization information.
// 5. Sort and return the full result set.
//
// For personal users, therefore, this will make 2 + n roundtrips, where n is the number of shared notebooks.
// For business users, this will make 2 + 2 + n roundtrips, where n is the number of nonbusiness shared notebooks.

- (void)listNotebooksWithCompletion:(ENSessionListNotebooksCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
    if (!self.isAuthenticated) {
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        return;
    }
    
    // Do we have a cached result that is unexpired?
    if ([self.notebooksCache count] > 0 && ([self.notebooksCacheDate timeIntervalSinceNow] * -1.0) < ENSessionNotebooksCacheValidity) {
        completion(self.notebooksCache, nil);
        return;
    }
    
    [self listNotebooks_cleanCache];
    
    ENSessionListNotebooksContext * context = [[ENSessionListNotebooksContext alloc] init];
    context.completion = completion;
    context.resultNotebooks = [[NSMutableArray alloc] init];
    [self listNotebooks_listNotebooksWithContext:context];
}

- (void)listWritableNotebooksWithCompletion:(ENSessionListNotebooksCompletionHandler)completion
{
    [self listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        NSMutableArray *writableNotebooks = [NSMutableArray array];
        for (ENNotebook *notebook in notebooks) {
            if ([notebook allowsWriting]) {
                [writableNotebooks addObject:notebook];
            }
        }
        completion(writableNotebooks, listNotebooksError);
    }];
}

- (void)listNotebooks_listNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore listNotebooksWithSuccess:^(NSArray * notebooks) {
        // Populate the result list with personal notebooks.
        for (EDAMNotebook * notebook in notebooks) {
            ENNotebook * result = [[ENNotebook alloc] initWithNotebook:notebook];
            [context.resultNotebooks addObject:result];
        }
        // Now get any shared notebooks records for the personal account.
        [weakSelf listNotebooks_listSharedNotebooksWithContext:context];
    } failure:^(NSError * error) {
        __strong typeof(weakSelf) self = weakSelf;
        if ([self isErrorDueToRestrictedAuth:error]) {
            // App has a single notebook auth token, so try getting linked notebooks.
            [self listNotebooks_listLinkedNotebooksWithContext:context];
            return;
        }
        ENSDKLogError(@"Error from listNotebooks in user's store: %@", error);
        [self listNotebooks_completeWithContext:context error:error];
    }];
}

- (void)listNotebooks_listSharedNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore listSharedNotebooksWithSuccess:^(NSArray * sharedNotebooks) {
        [weakSelf listNotebooks_listLinkedNotebooksWithContext:context];
    } failure:^(NSError *error) {
        ENSDKLogError(@"Error from listSharedNotebooks in user's store: %@", error);
        [weakSelf listNotebooks_completeWithContext:context error:error];
    }];
}

- (void)listNotebooks_listLinkedNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore listLinkedNotebooksWithSuccess:^(NSArray *linkedNotebooks) {
        __strong typeof(weakSelf) self = weakSelf;
        if (linkedNotebooks.count == 0) {
            [self listNotebooks_prepareResultsWithContext:context];
        } else {
            context.linkedPersonalNotebooks = [NSMutableArray arrayWithArray:linkedNotebooks];
            if ([self businessNoteStore]) {
                [self listNotebooks_fetchSharedBusinessNotebooksWithContext:context];
            } else {
                [self listNotebooks_fetchSharedNotebooksWithContext:context];
            }
        }
    } failure:^(NSError *error) {
        if ([self isErrorDueToRestrictedAuth:error]) {
            // App has a single notebook auth token, so skip to the end.
            [self listNotebooks_prepareResultsWithContext:context];
            return;
        }
        ENSDKLogError(@"Error from listLinkedNotebooks in user's store: %@", error);
        [self listNotebooks_completeWithContext:context error:error];
    }];
}

- (void)listNotebooks_fetchSharedBusinessNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    __weak typeof(self) weakSelf = self;
    [self.businessNoteStore listSharedNotebooksWithSuccess:^(NSArray *sharedNotebooks) {
        // Run through the results, and set each notebook keyed by its shareKey, which
        // is how we'll find corresponding linked notebooks.
        context.sharedBusinessNotebooks = [[NSMutableDictionary alloc] init];
        context.sharedBusinessNotebookGuids = [[NSCountedSet alloc] init];
        for (EDAMSharedNotebook * notebook in sharedNotebooks) {
            [context.sharedBusinessNotebooks setObject:notebook forKey:notebook.globalId];
            [context.sharedBusinessNotebookGuids addObject:notebook.notebookGuid];
        }
        
        // Now continue on to grab all of the linked notebooks for the business.
        [weakSelf listNotebooks_fetchBusinessNotebooksWithContext:context];
    } failure:^(NSError *error) {
        ENSDKLogError(@"Error from listSharedNotebooks in business store: %@", error);
        [weakSelf listNotebooks_completeWithContext:context error:error];
    }];
}

- (void)listNotebooks_fetchBusinessNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    __weak typeof(self) weakSelf = self;
    [self.businessNoteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        // Run through the results, and set each notebook keyed by its guid, which
        // is how we'll find it from the shared notebook.
        context.businessNotebooks = [[NSMutableDictionary alloc] init];
        for (EDAMNotebook * notebook in notebooks) {
            [context.businessNotebooks setObject:notebook forKey:notebook.guid];
        }
        [weakSelf listNotebooks_processBusinessNotebooksWithContext:context];
    } failure:^(NSError *error) {
        ENSDKLogError(@"Error from listNotebooks in business store: %@", error);
        [weakSelf listNotebooks_completeWithContext:context error:error];
    }];
}

- (void)listNotebooks_processBusinessNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    // Postprocess our notebook sets for business notebooks. For every linked notebook in the personal
    // account, check for a corresponding business shared notebook (by shareKey). If we find it, also
    // grab its corresponding notebook object from the business notebook list.
    for (EDAMLinkedNotebook * linkedNotebook in [context.linkedPersonalNotebooks copy]) {
        EDAMSharedNotebook * sharedNotebook = [context.sharedBusinessNotebooks objectForKey:linkedNotebook.sharedNotebookGlobalId];
        if (sharedNotebook) {
            // This linked notebook corresponds to a business notebook.
            EDAMNotebook * businessNotebook = [context.businessNotebooks objectForKey:sharedNotebook.notebookGuid];
            ENNotebook * result = [[ENNotebook alloc] initWithSharedNotebook:sharedNotebook forLinkedNotebook:linkedNotebook withBusinessNotebook:businessNotebook];
            
            [context.resultNotebooks addObject:result];
            [context.linkedPersonalNotebooks removeObjectIdenticalTo:linkedNotebook]; // OK since we're enumerating a copy.
        }
    }
    
    // Any remaining linked notebooks are personal shared notebooks. No shared notebooks?
    // Then go directly to results preparation.
    if (context.linkedPersonalNotebooks.count == 0) {
        [self listNotebooks_prepareResultsWithContext:context];
    } else {
        [self listNotebooks_fetchSharedNotebooksWithContext:context];
    }
}

- (void)listNotebooks_fetchSharedNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    // Fetch shared notebooks for any non-business linked notebooks remaining in the
    // array in the context. We will have already pulled out the linked notebooks that
    // were processed for business.
    context.pendingSharedNotebooks = context.linkedPersonalNotebooks.count;
    NSMutableDictionary * sharedNotebooks = [[NSMutableDictionary alloc] init];
    context.sharedNotebooks = sharedNotebooks;

    __weak typeof(self) weakSelf = self;
    for (EDAMLinkedNotebook * linkedNotebook in context.linkedPersonalNotebooks) {
        ENNoteStoreClient * noteStore = [self noteStoreForLinkedNotebook:linkedNotebook];
        if (linkedNotebook.sharedNotebookGlobalId == nil) {
            // sharedNotebookGlobalId is nil means it's a public notebook
            [self.userStore getPublicUserInfoWithUsername:linkedNotebook.username
                                                  success:^(EDAMPublicUserInfo *info) {
                                                      [noteStore getPublicNotebookWithUserID:[[info userId] intValue]
                                                                                   publicUri:linkedNotebook.uri
                                                                                     success:^(EDAMNotebook *sharedNotebook) {
                                                                                         [sharedNotebooks setObject:sharedNotebook forKey:linkedNotebook.guid];
                                                                                         [weakSelf listNotebooks_completePendingSharedNotebookWithContext:context];
                                                                                     } failure:^(NSError *error) {
                                                                                         context.error = error;
                                                                                         [weakSelf listNotebooks_completePendingSharedNotebookWithContext:context];
                                                                                     }];
                                                  } failure:^(NSError *error) {
                                                      context.error = error;
                                                      [weakSelf listNotebooks_completePendingSharedNotebookWithContext:context];
                                                  }];
        } else {
            [noteStore getSharedNotebookByAuthWithSuccess:^(EDAMSharedNotebook * sharedNotebook) {
                // Add the shared notebook to the map.
                [sharedNotebooks setObject:sharedNotebook forKey:linkedNotebook.guid];
                [weakSelf listNotebooks_completePendingSharedNotebookWithContext:context];
            } failure:^(NSError * error) {
                // failed to get the sharedNotebook from the service
                // the shared notebook could be deleted from the owner
                // we remove the linked notebook record from the context so it won't be listed in the result
                ENSDKLogError(@"Failed to get shared notebook for linked notebook record %@", linkedNotebook);
                [context.linkedPersonalNotebooks removeObject:linkedNotebook];
                context.error = error;
                [weakSelf listNotebooks_completePendingSharedNotebookWithContext:context];
            }];
        }
    }
}

- (void)listNotebooks_completePendingSharedNotebookWithContext:(ENSessionListNotebooksContext *)context
{
    if (--context.pendingSharedNotebooks == 0) {
        [self listNotebooks_processSharedNotebooksWithContext:context];
    }
}

- (void)listNotebooks_processSharedNotebooksWithContext:(ENSessionListNotebooksContext *)context
{
    // Process the results
    for (EDAMLinkedNotebook * linkedNotebook in context.linkedPersonalNotebooks) {
        id sharedNotebook = [context.sharedNotebooks objectForKey:linkedNotebook.guid];
        ENNotebook * result = nil;
        if ([sharedNotebook isMemberOfClass:[EDAMSharedNotebook class]]) {
            // shared notebook with individuals
            result = [[ENNotebook alloc] initWithSharedNotebook:sharedNotebook forLinkedNotebook:linkedNotebook];
        } else {
            // public notebook
            result = [[ENNotebook alloc] initWithPublicNotebook:sharedNotebook forLinkedNotebook:linkedNotebook];
        }
        [context.resultNotebooks addObject:result];
    }
    
    [self listNotebooks_prepareResultsWithContext:context];
}

- (void)listNotebooks_prepareResultsWithContext:(ENSessionListNotebooksContext *)context
{
    // If there's only one notebook, and it's not flagged as the default notebook for the account, then
    // we must be in a single-notebook auth scenario. In this case, simply override the flag so to a caller it
    // will appear to be the default anyway. Note that we only do this if it's not already the default. If a single
    // notebook result is already marked default, then it *could* be that there really is one notebook, and we don't
    // want to have the caller persist an override flag that might be inapplicable later.
    if (context.resultNotebooks.count == 1) {
        ENNotebook * soleNotebook = context.resultNotebooks[0];
        if (!soleNotebook.isDefaultNotebook) {
            soleNotebook.isDefaultNotebookOverride = YES;
        }
    }
    
    // Sort them by name. This is just a convenience for the caller in case they don't bother to sort them themselves.
    [context.resultNotebooks sortUsingComparator:^NSComparisonResult(ENNotebook * obj1, ENNotebook * obj2) {
        return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
    }];
    
    [self listNotebooks_completeWithContext:context error:nil];
}

- (void)listNotebooks_completeWithContext:(ENSessionListNotebooksContext *)context
                                    error:(NSError *)error
{
    self.notebooksCache = context.resultNotebooks;
    self.notebooksCacheDate = [NSDate date];
    
    context.completion(context.resultNotebooks, error);
}

- (void)listNotebooks_cleanCache
{
    self.notebooksCache = nil;
    self.notebooksCacheDate = nil;
}

#pragma mark - uploadNote

- (void)uploadNote:(ENNote *)note
          notebook:(ENNotebook *)notebook
        completion:(ENSessionUploadNoteCompletionHandler)completion
{
    [self uploadNote:note
              policy:ENSessionUploadPolicyCreate
          toNotebook:notebook
       orReplaceNote:nil
            progress:nil
          completion:completion];
}

- (void)uploadNote:(ENNote *)note
            policy:(ENSessionUploadPolicy)policy
        toNotebook:(ENNotebook *)notebook
     orReplaceNote:(ENNoteRef *)noteToReplace
          progress:(ENSessionProgressHandler)progress
        completion:(ENSessionUploadNoteCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
    
    if (!note) {
        ENSDKLogError(@"must specify note");
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeInvalidData userInfo:nil]);
        return;
    }
    
    if ((policy == ENSessionUploadPolicyReplace && !noteToReplace) ||
        (policy == ENSessionUploadPolicyReplaceOrCreate && !noteToReplace)) {
        ENSDKLogError(@"must specify existing ID when requesting a replacement policy");
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeInvalidData userInfo:nil]);
        return;
    }
    
    if (policy == ENSessionUploadPolicyCreate && noteToReplace) {
        ENSDKLogError(@"Can't use create policy when specifying an existing note ref. Ignoring.");
        noteToReplace = nil;
    }
    
    if (notebook && !notebook.allowsWriting) {
        [NSException raise:NSInvalidArgumentException format:@"a specified notebook must not be readonly"];
        return;
    }
    
    if (!self.isAuthenticated) {
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        return;
    }
    
    // Run size validation on any resources included with the note. This is done at upload time because
    // the sizes are a function of the user's service level, which can change.
    if (![note validateForLimits]) {
        ENSDKLogError(@"Note failed limits validation. Cannot upload. %@", self);
        completion(nil, [ENError noteSizeLimitReachedError]);
    }
    
    ENSessionUploadNoteContext * context = [[ENSessionUploadNoteContext alloc] init];
    if (noteToReplace) {
        context.note = [note EDAMNoteToReplaceServiceNoteGUID:noteToReplace.guid];
    } else {
        context.note = [note EDAMNote];
    }
    context.refToReplace = noteToReplace;
    context.notebook = notebook;
    context.policy = policy;
    context.completion = completion;
    context.progress = progress;
    
    [self uploadNote_determineDestinationWithContext:context];
}

- (void)uploadNote_determineDestinationWithContext:(ENSessionUploadNoteContext *)context
{
    // Begin prepping a resulting note ref.
    context.noteRef = [[ENNoteRef alloc] init];
    
    // If this app uses an app notebook and that notebook is linked, then no matter what the caller says,
    // we're going to need to use the explicit notebook destination to comply with shared notebook auth.
    if ([self appNotebookIsLinked]) {
        // Do we have a cached linked notebook record to use as a destination?
        EDAMLinkedNotebook * linkedNotebook = [self.preferences decodedObjectForKey:ENSessionPreferencesLinkedAppNotebook];
        if (linkedNotebook) {
            context.noteStore = [self noteStoreForLinkedNotebook:linkedNotebook];
            context.noteRef.type = ENNoteRefTypeShared;
            context.noteRef.linkedNotebook = [ENLinkedNotebookRef linkedNotebookRefFromLinkedNotebook:linkedNotebook];
            
            // Because we are using a linked app notebook, and authenticating to it with the shared auth model,
            // we must provide a notebook guid in the note or face an error.
            EDAMSharedNotebook * sharedNotebook = [self.preferences decodedObjectForKey:ENSessionPreferencesSharedAppNotebook];
            context.note.notebookGuid = sharedNotebook.notebookGuid;
        } else {
            // We don't have a linked notebook record to use. We need to go find one.
            [self uploadNote_findLinkedAppNotebookWithContext:context];
            return;
        }
    }
    
    if (!context.noteStore) {
        if (context.refToReplace) {
            context.noteStore = [self noteStoreForNoteRef:context.refToReplace];
            context.noteRef.type = context.refToReplace.type;
            context.noteRef.linkedNotebook = context.refToReplace.linkedNotebook;
        } else if (context.notebook.isBusinessNotebook) {
            context.noteStore = [self businessNoteStore];
            context.noteRef.type = ENNoteRefTypeBusiness;
        } else if (context.notebook.isLinked) {
            context.noteStore = [self noteStoreForLinkedNotebook:context.notebook.linkedNotebook];
            context.noteRef.type = ENNoteRefTypeShared;
            context.noteRef.linkedNotebook = [ENLinkedNotebookRef linkedNotebookRefFromLinkedNotebook:context.notebook.linkedNotebook];
        } else {
            // This is the normal case. Either the app has not specified a destination notebook, or the
            // notebook is personal.
            context.noteStore = [self primaryNoteStore];
            context.noteRef.type = ENNoteRefTypePersonal;
        }
    }
    
    if (context.refToReplace) {
        [self uploadNote_updateWithContext:context];
    } else {
        [self uploadNote_createWithContext:context];
    }
}

- (void)uploadNote_updateWithContext:(ENSessionUploadNoteContext *)context
{
    // If we're replacing a note, fixup the update date.
    context.note.updated = @([[NSDate date] edamTimestamp]);
    
    context.note.guid = context.refToReplace.guid;
    
    if (context.progress) {
        context.noteStore.uploadProgressHandler = context.progress;
    }

    __weak typeof(self) weakSelf = self;
    [context.noteStore updateNote:context.note success:^(EDAMNote * resultNote) {
        context.noteRef = context.refToReplace; // The result by definition has the same ref.
        [weakSelf uploadNote_completeWithContext:context error:nil];
    } failure:^(NSError *error) {
        if ([error.userInfo[@"parameter"] isEqualToString:@"Note.guid"]) {
            // We tried to replace a note that isn't there anymore. Now we look at the replacement policy.
            if (context.policy == ENSessionUploadPolicyReplaceOrCreate) {
                // Can't update it, just create it anew.
                context.note.guid = nil;
                context.policy = ENSessionUploadPolicyCreate;
                context.refToReplace = nil;
                
                // Go back to determining the destination before creating. We'll take into account a supplied
                // notebook at this point, which may actually be in a different place than the note we were
                // trying to replace. We don't have enough information otherwise to reliably place a new note
                // in the same notebook as the original one, so defaulting to a default notebook in a given
                // note store is less predictable than defaulting to the default overall. In practice, this
                // works out the same most of the time. (For app notebook apps, it'll end up in the app notebook
                // anyway of course.)
                [weakSelf uploadNote_determineDestinationWithContext:context];
                return;
            }
        }
        ENSDKLogError(@"Failed to updateNote for uploadNote: %@", error);
        [weakSelf uploadNote_completeWithContext:context error:error];
    }];
}

- (void)uploadNote_findLinkedAppNotebookWithContext:(ENSessionUploadNoteContext *)context
{
    // We know the app notebook is linked. List linked notebooks; we expect to find a single result.
    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore listLinkedNotebooksWithSuccess:^(NSArray * linkedNotebooks) {
        __strong typeof(weakSelf) self = weakSelf;
        if (linkedNotebooks.count < 1) {
            ENSDKLogInfo(@"Cannot find linked app notebook. Perhaps user deleted it?");
            // Uh-oh; there's no destination to use. We have to fail the request.
            NSError * error = [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeNotFound userInfo:nil];
            [self uploadNote_completeWithContext:context error:error];
            return;
        }
        if (linkedNotebooks.count > 1) {
            ENSDKLogInfo(@"Expected to find single linked notebook, found %lu", (unsigned long)linkedNotebooks.count);
        }
        // Take this notebook, and cache it.
        EDAMLinkedNotebook * linkedNotebook = linkedNotebooks[0];
        if (linkedNotebook.sharedNotebookGlobalId == nil) {
            // The notebook is a public notebook so it's read only. Fail the request with error.
            NSError * error = [NSError errorWithDomain:ENErrorDomain code:ENErrorCodePermissionDenied userInfo:nil];
            [self uploadNote_completeWithContext:context error:error];
            return;
        }
        [self.preferences encodeObject:linkedNotebook forKey:ENSessionPreferencesLinkedAppNotebook];
        
        // Go find the shared notebook that corresponds to this.
        [self uploadNote_findSharedAppNotebookWithContext:context];
    } failure:^(NSError * error) {
        ENSDKLogInfo(@"Failed to listLinkedNotebooks for uploadNote; turning into NotFound: %@", error);
        // Uh-oh; there's no destination to use. We have to fail the request.
        error = [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeNotFound userInfo:nil];
        [weakSelf uploadNote_completeWithContext:context error:error];
    }];
}

- (void)uploadNote_findSharedAppNotebookWithContext:(ENSessionUploadNoteContext *)context
{
    EDAMLinkedNotebook * linkedNotebook = [self.preferences decodedObjectForKey:ENSessionPreferencesLinkedAppNotebook];
    ENNoteStoreClient * linkedNoteStore = [self noteStoreForLinkedNotebook:linkedNotebook];
    __weak typeof(self) weakSelf = self;
    [linkedNoteStore getSharedNotebookByAuthWithSuccess:^(EDAMSharedNotebook *sharedNotebook) {
        __strong typeof(weakSelf) self = weakSelf;
        if (sharedNotebook) {
            // Persist the shared notebook record.
            [self.preferences encodeObject:sharedNotebook forKey:ENSessionPreferencesSharedAppNotebook];
            
            // Go back and redetermine the destination.
            [self uploadNote_determineDestinationWithContext:context];
        } else {
            ENSDKLogInfo(@"getSharedNotebookByAuth for uploadNote returned empty sharedNotebook; turning into NotFound.");
            // Uh-oh; there's no destination to use. We have to fail the request.
            NSError * error = [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeNotFound userInfo:nil];
            [self uploadNote_completeWithContext:context error:error];
        }
    } failure:^(NSError *error) {
        ENSDKLogInfo(@"Failed to getSharedNotebookByAuth for uploadNote; turning into NotFound: %@", error);
        // Uh-oh; there's no destination to use. We have to fail the request.
        error = [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeNotFound userInfo:nil];
        [weakSelf uploadNote_completeWithContext:context error:error];
    }];
}

- (void)uploadNote_createWithContext:(ENSessionUploadNoteContext *)context
{
    // Clear create and update dates. The service will set these to sensible defaults for a new note.
    context.note.created = context.note.updated = nil;
    
    // Write in the notebook guid if we're providing one.
    if (!context.note.notebookGuid) {
        context.note.notebookGuid = context.notebook.guid;
    }
    
    if (context.progress) {
        context.noteStore.uploadProgressHandler = context.progress;
    }
    __weak typeof(self) weakSelf = self;
    [context.noteStore createNote:context.note success:^(EDAMNote * resultNote) {
        context.noteRef.guid = resultNote.guid;
        [weakSelf uploadNote_completeWithContext:context error:nil];
    } failure:^(NSError * error) {
        context.noteRef = nil;
        ENSDKLogError(@"Failed to createNote for uploadNote: %@", error);
        [weakSelf uploadNote_completeWithContext:context error:error];
    }];
}

- (void)uploadNote_completeWithContext:(ENSessionUploadNoteContext *)context
                                 error:(NSError *)error
{
    context.noteStore.uploadProgressHandler = nil;
    if (context.completion) {
        context.completion(error ? nil : context.noteRef, error);
    }
}

#pragma mark - shareNote

- (void)shareNote:(ENNoteRef *)noteRef
       completion:(ENSessionShareNoteCompletionHandler)completion
{
    if (!self.isAuthenticated) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        }
        return;
    }

    ENNoteStoreClient * noteStore = [self noteStoreForNoteRef:noteRef];
    __weak typeof(self) weakSelf = self;
    [noteStore shareNoteWithGuid:noteRef.guid success:^(NSString * noteKey) {
        __strong typeof(weakSelf) self = weakSelf;
        NSString * shardId = [self shardIdForNoteRef:noteRef];
        NSString * shareUrl = [ENShareURLHelper shareURLStringForNoteGUID:noteRef.guid
                                                                  shardId:shardId
                                                                 shareKey:noteKey
                                                              serviceHost:self.sessionHost
                                                  encodedAdditionalString:nil];        
        if (completion) {
            completion(shareUrl, nil);
        }
    } failure:^(NSError * error) {
        ENSDKLogError(@"Failed to shareNote: %@", error);
        if (completion) {
            completion(nil, error);
        }
    }];
}

#pragma mark - deleteNote

- (void)deleteNote:(ENNoteRef *)noteRef
        completion:(ENSessionDeleteNoteCompletionHandler)completion
{
    if (!self.isAuthenticated) {
        if (completion) {
            completion([NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        }
        return;
    }

    ENNoteStoreClient * noteStore = [self noteStoreForNoteRef:noteRef];
    [noteStore deleteNoteWithGuid:noteRef.guid success:^(int32_t usn) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError * error) {
        ENSDKLogError(@"Failed to deleteNote: %@", error);
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - findNotes

- (void)findNotesWithSearch:(ENNoteSearch *)noteSearch
                 inNotebook:(ENNotebook *)notebook
                    orScope:(ENSessionSearchScope)scope
                  sortOrder:(ENSessionSortOrder)sortOrder
                 maxResults:(NSUInteger)maxResults
                 completion:(ENSessionFindNotesCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
        
    if (!self.isAuthenticated) {
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        return;
    }
    
    // App notebook scope is internally just an "all" search, because we don't a priori know where the app
    // notebook is. There's some room for a fast path in this flow if we have a saved linked record to a
    // linked app notebook, but that case is likely rare enough to prevent complexifying this code for.
    if (EN_FLAG_ISSET(scope, ENSessionSearchScopeAppNotebook)) {
        scope = ENSessionSearchScopeAll;
    }
    
    // Validate the scope and sort arguments.
    if (notebook && scope != ENSessionSearchScopeNone) {
        ENSDKLogInfo(@"No search scope necessary if notebook provided.");
        scope = ENSessionSearchScopeNone;
    } else if (!notebook && scope == ENSessionSearchScopeNone) {
        ENSDKLogInfo(@"Search scope or notebook must be specified. Defaulting to personal scope.");
        scope = ENSessionSearchScopeDefault;
    }
    
    BOOL requiresLocalMerge = NO;
    if (scope != ENSessionSearchScopeNone) {
        // Check for multiple scopes. Because linked scope can subsume multiple linked notebooks, that *always* triggers
        // the multiple scopes. If not, then both personal and business must be set together.
        if ((EN_FLAG_ISSET(scope, ENSessionSearchScopePersonal) && EN_FLAG_ISSET(scope, ENSessionSearchScopeBusiness)) ||
            EN_FLAG_ISSET(scope, ENSessionSearchScopePersonalLinked)) {
            // If we're asked for multiple scopes, relevance is not longer supportable (since we
            // don't know how to combine relevance on the client), so default to updated date,
            // which is probably the closest proxy to relevance.
            if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderRelevance)) {
                ENSDKLogError(@"Cannot sort by relevance across multiple search scopes. Using update date.");
                EN_FLAG_CLEAR(sortOrder, ENSessionSortOrderRelevance);
                EN_FLAG_SET(sortOrder, ENSessionSortOrderRecentlyUpdated);
            }
            requiresLocalMerge = YES;
        }
    }
    
    EDAMNotesMetadataResultSpec * resultSpec = [[EDAMNotesMetadataResultSpec alloc] init];
    resultSpec.includeNotebookGuid = @YES;
    resultSpec.includeTitle = @YES;
    resultSpec.includeCreated = @YES;
    resultSpec.includeUpdated = @YES;
    resultSpec.includeUpdateSequenceNum = @YES;
    
    EDAMNoteFilter * noteFilter = [[EDAMNoteFilter alloc] init];
    noteFilter.words = noteSearch.searchString;
    
    if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderTitle)) {
        noteFilter.order = @(NoteSortOrder_TITLE);
    } else if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderRecentlyCreated)) {
        noteFilter.order = @(NoteSortOrder_CREATED);
    } else if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderRecentlyUpdated)) {
        noteFilter.order = @(NoteSortOrder_UPDATED);
    } else if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderRelevance)) {
        noteFilter.order = @(NoteSortOrder_RELEVANCE);
    }
    
    // "Normal" sort is ascending for titles, and descending for dates and relevance.
    BOOL sortAscending = EN_FLAG_ISSET(sortOrder, ENSessionSortOrderTitle) ? YES : NO;
    if (EN_FLAG_ISSET(sortOrder, ENSessionSortOrderReverse)) {
        sortAscending = !sortAscending;
    }
    noteFilter.ascending = @(sortAscending);

    if (notebook) {
        noteFilter.notebookGuid = notebook.guid;
    }
    
    // Set up context.
    ENSessionFindNotesContext * context= [[ENSessionFindNotesContext alloc] init];
    context.completion = completion;
    context.scopeNotebook = notebook;
    context.scope = scope;
    context.sortOrder = sortOrder;
    context.noteFilter = noteFilter;
    context.resultSpec = resultSpec;
    context.maxResults = maxResults;
    context.findMetadataResults = [[NSMutableArray alloc] init];
    context.requiresLocalMerge = requiresLocalMerge;
    context.sortAscending = sortAscending;
    
    // If we have a scope notebook, we already know what notebook the results will appear in.
    // If we don't have a scope notebook, then we need to query for all the notebooks to determine
    // where to search.
    if (!context.scopeNotebook) {
        [self findNotes_listNotebooksWithContext:context];
        return;
    }
    
    // Go directly to the next step.
    [self findNotes_findInPersonalScopeWithContext:context];
}

- (void)findNotes_listNotebooksWithContext:(ENSessionFindNotesContext *)context
{
    // XXX: We do the full listNotebooks operation here, which is overkill in all situations,
    // and could wind us up doing a bunch of extra work. Optimization is to only look at -listNotebooks
    // if we're personal scope, and -listLinkedNotebooks for linked and business, without ever
    // authenticating to other note stores. But it's also true that a findNotes may well be followed
    // quickly by a fetchNote(s), which is going to require the full notebook list anyway, and by then
    // it'll be cached.
    __weak typeof(self) weakSelf = self;
    [self listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        if (notebooks) {
            context.allNotebooks = notebooks;
            [weakSelf findNotes_findInPersonalScopeWithContext:context];
        } else {
            ENSDKLogError(@"findNotes: Failed to list notebooks. %@", listNotebooksError);
            [weakSelf findNotes_completeWithContext:context error:listNotebooksError];
        }
    }];
}

- (void)findNotes_findInPersonalScopeWithContext:(ENSessionFindNotesContext *)context
{
    BOOL skipPersonalScope = NO;
    // Skip the personal scope if the scope notebook isn't personal, or if the scope
    // flag doesn't include personal.
    if (context.scopeNotebook) {
        // If the scope notebook isn't personal, skip personal.
        if (context.scopeNotebook.isLinked) {
            skipPersonalScope = YES;
        }
    } else if (!EN_FLAG_ISSET(context.scope, ENSessionSearchScopePersonal)) {
        // If the caller didn't request personal scope.
        skipPersonalScope = YES;
    } else if ([self appNotebookIsLinked]) {
        // If we know this is an app notebook scoped app, and we know the app notebook is not personal.
        skipPersonalScope = YES;
    }

    // If we're skipping personal scope, proceed directly to business scope.
    if (skipPersonalScope) {
        [self findNotes_findInBusinessScopeWithContext:context];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.primaryNoteStore findNotesMetadataWithFilter:context.noteFilter
                                            maxResults:context.maxResults
                                            resultSpec:context.resultSpec
                                               success:^(NSArray *notesMetadataList) {
                                                   [context.findMetadataResults addObjectsFromArray:notesMetadataList];
                                                   [weakSelf findNotes_findInBusinessScopeWithContext:context];
                                               } failure:^(NSError *error) {
                                                   ENSDKLogError(@"findNotes: Failed to find notes (personal). %@", error);
                                                   [weakSelf findNotes_completeWithContext:context error:error];
                                               }];
}

- (void)findNotes_findInBusinessScopeWithContext:(ENSessionFindNotesContext *)context
{
    // Skip the business scope if the user is not a business user, or the scope notebook
    // is not a business notebook, or the business scope is not included.
    if (![self isBusinessUser] ||
        (context.scopeNotebook && !context.scopeNotebook.isBusinessNotebook) ||
        (!context.scopeNotebook && !EN_FLAG_ISSET(context.scope, ENSessionSearchScopeBusiness))) {
        [self findNotes_findInLinkedScopeWithContext:context];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.businessNoteStore findNotesMetadataWithFilter:context.noteFilter
                                             maxResults:context.maxResults
                                             resultSpec:context.resultSpec
                                                success:^(NSArray *notesMetadataList) {
                                                    [context.findMetadataResults addObjectsFromArray:notesMetadataList];

                                                    // Remember which note guids came from the business. We'll use this later to
                                                    // determine if we're worried about an inability to map back to notebooks.
                                                    context.resultGuidsFromBusiness = [NSSet setWithArray:[notesMetadataList valueForKeyPath:@"guid"]];
                                                    
                                                    [weakSelf findNotes_findInLinkedScopeWithContext:context];
                                                } failure:^(NSError *error) {
                                                    __strong typeof(weakSelf) self = weakSelf;
                                                    if ([self isErrorDueToRestrictedAuth:error]) {
                                                        // This is a business user, but apparently has an app notebook restriction that's
                                                        // not in the business. Go look in linked scope.
                                                        [self findNotes_findInLinkedScopeWithContext:context];
                                                        return;
                                                    }
                                                    ENSDKLogError(@"findNotes: Failed to find notes (business). %@", error);
                                                    [self findNotes_completeWithContext:context error:error];
                                                }];
}

- (void)findNotes_findInLinkedScopeWithContext:(ENSessionFindNotesContext *)context
{
    // Skip linked scope if scope notebook is not a personal linked notebook, or if the
    // linked scope is not included.
    if (context.scopeNotebook) {
        if (!context.scopeNotebook.isLinked || context.scopeNotebook.isBusinessNotebook) {
            [self findNotes_processResultsWithContext:context];
            return;
        }
    } else if (!EN_FLAG_ISSET(context.scope, ENSessionSearchScopePersonalLinked)) {
        [self findNotes_processResultsWithContext:context];
        return;
    }
    
    // Build a list of all the linked notebooks that we need to run the search against.
    context.linkedNotebooksToSearch = [[NSMutableArray alloc] init];
    if (context.scopeNotebook) {
        [context.linkedNotebooksToSearch addObject:context.scopeNotebook];
    } else {
        for (ENNotebook * notebook in context.allNotebooks) {
            if (notebook.isLinked && !notebook.isBusinessNotebook) {
                [context.linkedNotebooksToSearch addObject:notebook];
            }
        }
    }
    
    [self findNotes_nextFindInLinkedScopeWithContext:context];
}

- (void)findNotes_nextFindInLinkedScopeWithContext:(ENSessionFindNotesContext *)context
{
    if (context.linkedNotebooksToSearch.count == 0) {
        [self findNotes_processResultsWithContext:context];
        return;
    }
    
    // Pull the first notebook off the list of pending linked notebooks.
    ENNotebook * notebook = context.linkedNotebooksToSearch[0];
    [context.linkedNotebooksToSearch removeObjectAtIndex:0];
    
    ENNoteStoreClient * noteStore = [self noteStoreForLinkedNotebook:notebook.linkedNotebook];
    EDAMNoteFilter * noteFilter = [context.noteFilter copy];
    if ([notebook isJoinedPublic]) {
        // https://dev.evernote.com/doc/reference/NoteStore.html#Fn_NoteStore_findNotesMetadata
        // to search joined public notebook, the auth token can be nil, but notebookGuid must be set
        noteFilter.notebookGuid = notebook.guid;
    }
    __weak typeof(self) weakSelf = self;
    [noteStore findNotesMetadataWithFilter:noteFilter
                                maxResults:context.maxResults
                                resultSpec:context.resultSpec
                                   success:^(NSArray *notesMetadataList) {
                                       // Do it again with the next linked notebook in the list.
                                       [context.findMetadataResults addObjectsFromArray:notesMetadataList];
                                       [weakSelf findNotes_nextFindInLinkedScopeWithContext:context];
                                   } failure:^(NSError *error) {
                                       ENSDKLogError(@"findNotes: Failed to find notes (linked). notebook = %@; %@", notebook, error);
                                       [weakSelf findNotes_completeWithContext:context error:error];
                                   }];
}

- (void)findNotes_processResultsWithContext:(ENSessionFindNotesContext *)context
{
    // OK, now we have a complete list of note refs objects. If we need to do a local sort, then do so.
    if (context.requiresLocalMerge) {
        [context.findMetadataResults sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            EDAMNoteMetadata * m1, * m2;
            if (context.sortAscending) {
                m1 = (EDAMNoteMetadata *)obj1;
                m2 = (EDAMNoteMetadata *)obj2;
            } else {
                m1 = (EDAMNoteMetadata *)obj2;
                m2 = (EDAMNoteMetadata *)obj1;
            }
            if (EN_FLAG_ISSET(context.sortOrder, ENSessionSortOrderRecentlyCreated)) {
                return [m1.created compare:m2.created];
            } else if (EN_FLAG_ISSET(context.sortOrder, ENSessionSortOrderRecentlyUpdated)) {
                return [m1.updated compare:m2.updated];
            } else {
                return [m1.title compare:m2.title options:NSCaseInsensitiveSearch];
            }
        }];
    }
    
    // Prepare a dictionary of all notebooks by GUID so lookup below is fast.
    NSMutableDictionary * notebooksByGuid = nil;
    if (!context.scopeNotebook) {
        notebooksByGuid = [[NSMutableDictionary alloc] init];
        for (ENNotebook * notebook in context.allNotebooks) {
            notebooksByGuid[notebook.guid] = notebook;
        }
    }
    
    // Turn the metadata list into a list of note refs.
    NSMutableArray * findNotesResults = [[NSMutableArray alloc] init];
    
    for (EDAMNoteMetadata * metadata in context.findMetadataResults) {
        ENNoteRef * ref = [[ENNoteRef alloc] init];
        ref.guid = metadata.guid;
        
        // Figure out which notebook this note belongs to. (If there's a scope notebook, it always belongs to that one.)
        ENNotebook * notebook = context.scopeNotebook ?: notebooksByGuid[metadata.notebookGuid];
        if (!notebook) {
            // This is probably a business notebook that we haven't explicitly joined, so we don't have it in our list.
            if (![context.resultGuidsFromBusiness containsObject:metadata.guid]) {
                // Oh, it's not from the business. We really can't find it. This is an error.
                ENSDKLogError(@"Found note metadata but can't determine owning notebook by guid. Metadata = %@", metadata);
            }
            continue;
        }

        if (notebook.isBusinessNotebook) {
            ref.type = ENNoteRefTypeBusiness;
            ref.linkedNotebook = [ENLinkedNotebookRef linkedNotebookRefFromLinkedNotebook:notebook.linkedNotebook];
        } else if (notebook.isLinked) {
            ref.type = ENNoteRefTypeShared;
            ref.linkedNotebook = [ENLinkedNotebookRef linkedNotebookRefFromLinkedNotebook:notebook.linkedNotebook];
        } else {
            ref.type = ENNoteRefTypePersonal;
        }
        
        ENSessionFindNotesResult * result = [[ENSessionFindNotesResult alloc] init];
        result.noteRef = ref;
        result.notebook = notebook;
        result.title = metadata.title;
        result.created = [NSDate dateWithEDAMTimestamp:[metadata.created longLongValue]];
        result.updated = [NSDate dateWithEDAMTimestamp:[metadata.updated longLongValue]];
        result.updateSequenceNum = [metadata.updateSequenceNum intValue];
        
        [findNotesResults addObject:result];
        
        // If the caller specified a max result count, and we've reached it, then stop fixing up
        // results here.
        if (context.maxResults > 0 && findNotesResults.count >= context.maxResults) {
            break;
        }
    }
    
    context.results = findNotesResults;
    [self findNotes_completeWithContext:context error:nil];
}

- (void)findNotes_completeWithContext:(ENSessionFindNotesContext *)context error:(NSError *)error
{
    if (error) {
        context.completion(nil, error);
    } else {
        context.completion(context.results, nil);
    }
}

#pragma mark - downloadNote

- (void)downloadNote:(ENNoteRef *)noteRef
            progress:(ENSessionProgressHandler)progress
          completion:(ENSessionDownloadNoteCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
    
    if (!noteRef) {
        ENSDKLogError(@"noteRef parameter is required to get download note");
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeInvalidData userInfo:nil]);
        return;
    }
    
    if (!self.isAuthenticated) {
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        return;
    }

    // Find the note store client that works with this note.
    ENNoteStoreClient * noteStore = [self noteStoreForNoteRef:noteRef];
    
    if (progress) {
        noteStore.downloadProgressHandler = progress;
    }
    
    // Fetch by guid. Always get the content and resources.
    [noteStore getNoteWithGuid:noteRef.guid withContent:YES withResourcesData:YES withResourcesRecognition:NO withResourcesAlternateData:NO success:^(EDAMNote * note) {
        
        // Create an ENNote from the EDAMNote.
        ENNote * resultNote = [[ENNote alloc] initWithServiceNote:note];
        
        noteStore.downloadProgressHandler = nil;
        completion(resultNote, nil);
    } failure:^(NSError * error) {
        noteStore.downloadProgressHandler = nil;
        completion(nil, error);
    }];
}

#pragma mark - downloadThumbnailForNote

- (void)downloadThumbnailForNote:(ENNoteRef *)noteRef
                    maxDimension:(NSUInteger)maxDimension
                      completion:(ENSessionDownloadNoteThumbnailCompletionHandler)completion
{
    if (!completion) {
        [NSException raise:NSInvalidArgumentException format:@"handler required"];
        return;
    }
    
    if (!noteRef) {
        ENSDKLogError(@"noteRef parameter is required to get download thumbnail");
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeInvalidData userInfo:nil]);
        return;
    }
    
    if (!self.isAuthenticated) {
        completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeAuthExpired userInfo:nil]);
        return;
    }
    
    // Clamp the maxDimension. Let 0 through as a sentinel for unspecified, and if the value is
    // already greater than the max we provide, then remove the parameter.
    if (maxDimension >= 300) {
        maxDimension = 0;
    }
    
    // Get over to a concurrent background queue.
    dispatch_async(self.thumbnailQueue, ^{
        // Get the info we need for this note ref, then construct a standard request for the thumbnail.
        NSString * authToken = [self authenticationTokenForNoteRef:noteRef];
        NSString * shardId = [self shardIdForNoteRef:noteRef];
        
        if (!authToken || !shardId) {
            completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeUnknown userInfo:nil]);
            return;
        }
        
        // Only append the size param if we are explicitly providing one.
        NSString * sizeParam = nil;
        if (maxDimension > 0) {
            sizeParam = [NSString stringWithFormat:@"?size=%lu", (unsigned long)maxDimension];
        }
        
        NSString * urlString = [NSString stringWithFormat:@"https://%@/shard/%@/thm/note/%@%@", self.sessionHost, shardId, noteRef.guid, sizeParam ?: @""];
        NSString * postBody = [NSString stringWithFormat:@"auth=%@", [authToken en_stringByUrlEncoding]];
        
        NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [postBody dataUsingEncoding:NSUTF8StringEncoding];
        [request addValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)request.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
        [request addValue:self.sessionHost forHTTPHeaderField:@"Host"];
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * thumbnailData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        UIImage * thumbnail = nil;
        if (!thumbnailData) {
            ENSDKLogError(@"Failed to get thumb data at url %@", urlString);
        } else {
            thumbnail = [UIImage imageWithData:thumbnailData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (thumbnail) {
                completion(thumbnail, nil);
            } else {
                if (!error) {
                    completion(nil, [NSError errorWithDomain:ENErrorDomain code:ENErrorCodeUnknown userInfo:nil]);
                } else {
                    completion(nil, error);                    
                }
            }
        });
    });
}

#pragma mark - Interaction with Evernote app

- (BOOL)viewNoteInEvernote:(ENNoteRef *)noteRef {
    if (IsEvernoteInstalled() == NO) {
        return NO;
    }
    
    NSString *viewNoteURLScheme = [NSString stringWithFormat:@"evernote:///view/%d/%@/%@/%@/", self.userID, [self shardIdForNoteRef:noteRef], noteRef.guid, noteRef.guid];
    return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:viewNoteURLScheme]];
}

#pragma mark - Private routines

#pragma mark - API helpers

- (BOOL)isErrorDueToRestrictedAuth:(NSError *)error
{
    int edamError = [error.userInfo[@"EDAMErrorCode"] intValue];
    NSString * parameter = error.userInfo[@"parameter"];
    if (edamError == EDAMErrorCode_PERMISSION_DENIED && [parameter isEqualToString:@"authenticationToken"]) {
        return YES;
    }
    return NO;
}

#pragma mark - Credential Store

- (ENCredentialStore *)credentialStore
{
    ENCredentialStore * store = [self.preferences decodedObjectForKey:ENSessionPreferencesCredentialStore];
    if (!store) {
        // Try loading from the previous location in app'd defaults.
        store = [ENCredentialStore loadCredentialsFromAppDefaults];
        if (store) {
            // Oh, we found it there? OK, put it into our own prefs vault immediately.
            [self.preferences encodeObject:store forKey:ENSessionPreferencesCredentialStore];
        }
    }
    if (!store) {
        store = [[ENCredentialStore alloc] init];
    }
    return store;
}

- (ENCredentials *)credentialsForHost:(NSString *)host
{
    return [[self credentialStore] credentialsForHost:host];
}

- (void)addCredentials:(ENCredentials *)credentials
{
    ENCredentialStore * store = [self credentialStore];
    [store addCredentials:credentials];
    [self saveCredentialStore:store];
}

- (void)saveCredentialStore:(ENCredentialStore *)credentialStore
{
    [self.preferences encodeObject:credentialStore forKey:ENSessionPreferencesCredentialStore];
}

#pragma mark - Credentials & Auth

- (ENCredentials *)primaryCredentials
{
    //XXX: Is here a good place to check for no credentials and trigger an unauthed state?
    return [self credentialsForHost:self.sessionHost];
}

- (EDAMAuthenticationResult *)validBusinessAuthenticationResult
{
    NSAssert(![NSThread isMainThread], @"Cannot authenticate to business on main thread");
    EDAMAuthenticationResult * auth = [self.authCache authenticationResultForBusiness];
    if (!auth) {
        auth = [self.userStore authenticateToBusiness];
        [self.authCache setAuthenticationResultForBusiness:auth];
        self.businessUser = auth.user;
        [self.preferences encodeObject:self.businessUser forKey:ENSessionPreferencesBusinessUser];
    }
    return auth;
}

- (ENAuthCache *)authCache
{
    if (!_authCache) {
        _authCache = [[ENAuthCache alloc] init];
    }
    return _authCache;
}

- (void)notifyAuthenticationChanged
{
    if (self.isAuthenticated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ENSessionDidAuthenticateNotification object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ENSessionDidUnauthenticateNotification object:self];
    }
}

#pragma mark - Store clients

- (ENUserStoreClient *)userStore
{
    if (!_userStore && self.primaryAuthenticationToken) {
        _userStore = [ENUserStoreClient userStoreClientWithUrl:[self userStoreUrl] authenticationToken:self.primaryAuthenticationToken];
    }
    return _userStore;
}

- (ENNoteStoreClient *)primaryNoteStore
{
    if (!_primaryNoteStore) {
        if (DeveloperToken) {
            _primaryNoteStore = [ENNoteStoreClient noteStoreClientWithUrl:NoteStoreUrl authenticationToken:DeveloperToken];
        } else {
            ENCredentials * credentials = [self primaryCredentials];
            if (credentials) {
                _primaryNoteStore = [ENNoteStoreClient noteStoreClientWithUrl:credentials.noteStoreUrl authenticationToken:credentials.authenticationToken];
            }
        }
    }
    return _primaryNoteStore;
}

- (ENBusinessNoteStoreClient *)businessNoteStore
{
    if (!_businessNoteStore && [self isBusinessUser]) {
        ENBusinessNoteStoreClient * client = [ENBusinessNoteStoreClient noteStoreClientForBusiness];
        client.delegate = self;
        _businessNoteStore = client;
    }
    return _businessNoteStore;
}

- (ENNoteStoreClient *)noteStoreForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
{
    ENLinkedNotebookRef * linkedNotebookRef = [ENLinkedNotebookRef linkedNotebookRefFromLinkedNotebook:linkedNotebook];
    ENLinkedNoteStoreClient * linkedClient = [ENLinkedNoteStoreClient noteStoreClientForLinkedNotebookRef:linkedNotebookRef];
    linkedClient.delegate = self;
    return linkedClient;
}

- (ENNoteStoreClient *)noteStoreForNoteRef:(ENNoteRef *)noteRef
{
    if (noteRef.type == ENNoteRefTypePersonal) {
        return [self primaryNoteStore];
    } else if (noteRef.type == ENNoteRefTypeBusiness) {
        return [self businessNoteStore];
    } else if (noteRef.type == ENNoteRefTypeShared) {
        ENLinkedNoteStoreClient * linkedClient = [ENLinkedNoteStoreClient noteStoreClientForLinkedNotebookRef:noteRef.linkedNotebook];
        linkedClient.delegate = self;
        return linkedClient;
    }
    return nil;
}

- (ENNoteStoreClient *)noteStoreForNotebook:(ENNotebook *)notebook
{
    if ([notebook isBusinessNotebook]) {
        return [self businessNoteStore];
    } else if ([notebook isLinked]) {
        return [self noteStoreForLinkedNotebook:notebook.linkedNotebook];
    } else {
        return [self primaryNoteStore];
    }
    return nil;
}

- (NSString *)shardIdForNoteRef:(ENNoteRef *)noteRef
{
    if (noteRef.type == ENNoteRefTypePersonal) {
        return self.user.shardId;
    } else if (noteRef.type == ENNoteRefTypeBusiness) {
        return self.businessUser.shardId;
    } else if (noteRef.type == ENNoteRefTypeShared) {
        return noteRef.linkedNotebook.shardId;
    }
    return nil;
}

- (NSString *)authenticationTokenForNoteRef:(ENNoteRef *)noteRef
{
    // Must be on background thread, because we may need to go over the wire to get a
    // noncached token.
    NSAssert(![NSThread isMainThread], @"Cannot get auth token on main thread");
    
    NSString * token = nil;
    
    // Because this method is called from outside the normal exception handlers in the user/note
    // store objects, it requires protection from EDAM and Thrift exceptions.
    @try {
        if (noteRef.type == ENNoteRefTypePersonal) {
            token = self.primaryAuthenticationToken;
        } else if (noteRef.type == ENNoteRefTypeBusiness) {
            token = [self validBusinessAuthenticationResult].authenticationToken;
        } else if (noteRef.type == ENNoteRefTypeShared) {
            token = [self authenticationTokenForLinkedNotebookRef:noteRef.linkedNotebook];
        }
    } @catch (NSException * e) {
        ENSDKLogError(@"Caught exception getting auth token for note ref %@: %@", noteRef, e);
        token = nil;
    }
    
    return token;
}

#pragma mark - Preferences helpers

- (NSString *)currentProfileName
{
    return [self.preferences objectForKey:ENSessionPreferencesCurrentProfileName];
}

- (void)setCurrentProfileNameFromHost:(NSString *)host
{
    NSString * profileName = nil;
    if ([host isEqualToString:ENSessionBootstrapServerBaseURLStringUS]) {
        profileName = ENBootstrapProfileNameInternational;
    } else if ([host isEqualToString:ENSessionBootstrapServerBaseURLStringCN]) {
        profileName = ENBootstrapProfileNameChina;
    }
    [self.preferences setObject:profileName forKey:ENSessionPreferencesCurrentProfileName];
}

- (NSString *)userStoreUrl
{
    // If the host string includes an explict port (e.g., foo.bar.com:8080), use http. Otherwise https.
    // Use a simple regex to check for a colon and port number suffix.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*:[0-9]+"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:self.sessionHost
                                                        options:0
                                                          range:NSMakeRange(0, [self.sessionHost length])];
    BOOL hasPort = (numberOfMatches > 0);
    NSString *scheme = (hasPort) ? @"http" : @"https";
    return [NSString stringWithFormat:@"%@://%@/edam/user", scheme, self.sessionHost];
}

#pragma mark - ENBusinessNoteStoreClientDelegate

- (NSString *)authenticationTokenForBusinessStoreClient:(ENBusinessNoteStoreClient *)client
{
    EDAMAuthenticationResult * auth = [self validBusinessAuthenticationResult];
    return auth.authenticationToken;
}

- (NSString *)noteStoreUrlForBusinessStoreClient:(ENBusinessNoteStoreClient *)client
{
    EDAMAuthenticationResult * auth = [self validBusinessAuthenticationResult];
    return auth.noteStoreUrl;
}

#pragma mark - ENLinkedNoteStoreClientDelegate

- (NSString *)authenticationTokenForLinkedNotebookRef:(ENLinkedNotebookRef *)linkedNotebookRef
{
    NSAssert(![NSThread isMainThread], @"Cannot authenticate to linked notebook on main thread");
    
    // use nil token for joined public notebook
    if (linkedNotebookRef.sharedNotebookGlobalId == nil) {
        return nil;
    }
    
    // See if we have auth data already for this notebook.
    EDAMAuthenticationResult * auth = [self.authCache authenticationResultForLinkedNotebookGuid:linkedNotebookRef.guid];
    if (!auth) {
        // Create a temporary note store client for the linked note store, with our primary auth token,
        // in order to authenticate to the shared notebook.
        ENNoteStoreClient * linkedNoteStore = [ENNoteStoreClient noteStoreClientWithUrl:linkedNotebookRef.noteStoreUrl authenticationToken:self.primaryAuthenticationToken];
        auth = [linkedNoteStore authenticateToSharedNotebookWithGlobalId:linkedNotebookRef.sharedNotebookGlobalId];
        [self.authCache setAuthenticationResult:auth forLinkedNotebookGuid:linkedNotebookRef.guid];
    }
    return auth.authenticationToken;
}

#pragma mark - ENAuthenticatorDelegate

- (ENUserStoreClient *)userStoreClientForBootstrapping
{
    // The user store for bootstrapping does not require authenticated access.
    return [ENUserStoreClient userStoreClientWithUrl:[self userStoreUrl] authenticationToken:nil];
}

- (void)authenticatorDidAuthenticateWithCredentials:(ENCredentials *)credentials authInfo:(NSDictionary *)authInfo
{
    self.isAuthenticated = YES;
    [self addCredentials:credentials];
    [self setCurrentProfileNameFromHost:credentials.host];
    self.sessionHost = credentials.host;
    self.primaryAuthenticationToken = credentials.authenticationToken;
    BOOL appNotebookIsLinked = [[authInfo objectForKey:ENOAuthAuthenticatorAuthInfoAppNotebookIsLinked] boolValue];
    if (appNotebookIsLinked) {
        [self.preferences setObject:@YES forKey:ENSessionPreferencesAppNotebookIsLinked];
    }
    [self performPostAuthentication];
}

- (void)authenticatorDidFailWithError:(NSError *)error
{
    [self completeAuthenticationWithError:error];
}

#pragma mark - Notification handlers

- (void)storeClientFailedAuthentication:(NSNotification *)notification
{
    if (notification.object == [self primaryNoteStore]) {
        ENSDKLogError(@"Primary note store operation failed authentication. Unauthenticating.");
        [self unauthenticate];
    }
}

#pragma mark - Keychain Sharing Helpers

// programatically find bundleSeedId/App ID Prefix
+ (NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

@end

#pragma mark - Default logger

@implementation ENSessionDefaultLogger
- (void)evernoteLogInfoString:(NSString *)str;
{
    NSLog(@"ENSDK: %@", str);
}

- (void)evernoteLogErrorString:(NSString *)str;
{
    NSLog(@"ENSDK ERROR: %@", str);
}
@end

#pragma mark - Local class definitions

@implementation ENSessionFindNotesResult
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; title = \"%@\"; notebook name = \"%@\"; created = %@; updated = %@; usn = %d; noteRef = %p>",
            [self class], self, self.title, self.notebook.name, self.created, self.updated, self.updateSequenceNum, self.noteRef];
}
@end

#pragma mark - Private context definitions
                                                
@implementation ENSessionListNotebooksContext
@end

@implementation ENSessionUploadNoteContext
@end

@implementation ENSessionFindNotesContext
@end
