Migrating from Evernote SDK for iOS 1.x
---

The Evernote Cloud SDK for iOS is the successor to the "classic" Evernote SDK, but it is not syntactically plug-compatible with that SDK. (You can't just replace it and recompile successfully.) However, modifying your app to accommodate the newer SDK is actually quite easy. Here's what you'll need to do.

**Note** Some apps cannot be migrated, because some functionality (like invoking the Evernote app to perform various functions for you) is not part of the Cloud SDK. 

### Import the Advanced headers 

Your code uses the EDAM API directly, which is considered "advanced" functionality in the new SDK.  In all the places where you used to `#import "EvernoteSDK.h"`, instead `#import <ENSDK/Advanced/ENSDKAdvanced.h>`. This will give you access to the classes you need.

### Know your key classes

The class through which you interface with the SDK is `ENSession` (not `EvernoteSession`). Get the singleton instance with `-sharedSession`. 

The note store client object is now `ENNoteStoreClient` (instead of `EvernoteNoteStore`). Similarly, the user store client is now `ENUserStoreClient`. The methods for calling Evernote API methods on these objects have the same signatures and behavior as previously, but you obtain the client objects slightly differently (see below).

### Update your app delegate

You have some code somewhere in your app startup that looks like this:

    [EvernoteSession setSharedSessionHost:EVERNOTE_HOST
                              consumerKey:CONSUMER_KEY  
                           consumerSecret:CONSUMER_SECRET];

Change it to:

	[ENSession setSharedSessionConsumerKey:CONSUMER_KEY
	  						consumerSecret:CONSUMER_SECRET
						      optionalHost:nil];

(The optional host is only set if you're using the sandbox, in which case set it to `ENSessionHostSandbox`)

### Authenticate with the shared session

The method and behavior should be the same, but `-authenticateWithViewController:completion:` is now a method on `ENSession`.

### Get the note store client for Evernote functions

Once authenticated, the shared session knows how to provide multiple note store clients depending on what you want:

    -(ENNoteStoreClient *)primaryNoteStore;
    -(ENNoteStoreClient *)businessNoteStore;
    -(ENNoteStoreClient *)noteStoreForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook;

The primary note store is always valid, and accesses a user's personal data. The business note store will be `nil` unless the user is connected to a business. Do not instantiate the store clients directly. The session will handle authenticating to linked and business note stores for you automatically. Once you have this object, you can use it to make the same EDAM calls you were making before; the signatures and behavior are identical. 

### Update EDAM primitive property access

The new version of the EDAM classes (like `EDAMNote`, etc) have *all* properties defined as objects. There is no change for most properties, which are strings, embedded other objects, etc. The properties that represent primitive types (like integers and timestamps and BOOLs) are now stored as `NSNumber` objects. Look at their definition in the headers (e.g. EDAMTypes.h) to see what the underlying type is in the inline comment, and use `NSNumber`'s accessors for retrieving them:

EDAM type  | NSNumber getter
------------- | -------------
BOOL  | `-boolValue`
int16_t | `-shortValue`
int32_t  | `-intValue`
int | `-intValue`
int64_t  | `-longLongValue`
double | `-doubleValue`
EDAMTimestamp | `-longLongValue`

This change results in far less code in the SDK, but it's important to double-check the access points in your code. For example, if you look at a BOOL property, you must do e.g.

    if ([resource.active boolValue] == YES) {
        ....
    }

and NOT
 
    // don't do this
    if (resource.active) {
    }

or your logic won't work as expected.
