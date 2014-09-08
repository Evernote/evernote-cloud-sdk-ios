Getting Started with the Evernote Cloud SDK for iOS
---

This document covers getting set up with the Cloud SDK, some quick examples, and some discussion of the primary classes. 

### Hello World!

Here's a quick example of how easy it is to create and upload a new note from your app:

	ENNote * note = [[ENNote alloc] init];
	note.content = [ENNoteContent noteContentWithString:@"Hello, World!"];
	note.title = @"My First Note";
	[[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef * noteRef, NSError * uploadNoteError) {
		// ...
	}];

This creates a new, plaintext note, with a title, and uploads it to the user's default notebook. All you need to do first is get your app setup with the SDK. Here's how.

Setup
-----

### Register for an Evernote API key (and secret)...

You can do this on the [Evernote Developers portal page](http://dev.evernote.com/documentation/cloud/). Most applications will want to do this-- it's easy and instant. During development, you will point your app at Evernote's "sandbox" development environment. When you are ready to test on production, we will upgrade your key. (You can create test accounts on sandbox by just going to [sandbox.evernote.com](http://sandbox.evernote.com)).

### ...or get a Developer Token

You can also just test-drive the SDK against your personal production Evernote account, if you're afraid of commitment or are building a one-off tool for yourself. [Get a developer token here](https://www.evernote.com/api/DeveloperToken.action). Make sure to then use the alternate setup instructions given in the "Modify Your App Delegate" section below.

### Build and include the framework

You have a few options:

- (Recommended) Open up terminal, cd into the root folder of the SDK repo you cloned and

		cd scripts;
		./build_framework.sh
		(if you see error '-bash: ./build_framework.sh: Permission denied' from the above line, please execute 'chmod +x build_framework.sh'
		to give your script execute permission and do the above)

	The script will generate a universal ENSDK.framework library for both the simulator and the device. After the build finishes, you can see where the product is generated from the build log:

		Framework built successfully! Please find in /Users/echeng/Documents/Evernote/evernote-sdk-ios-new/scripts/..//Products/ENSDK.framework

	Please add the ENSDK.framework and the ENSDKResources.bundle in the Products folder into your projects. Make sure you check "Copy items into destination group's folder (if needed)" This should

- (Alternative) If you want to build the entire SDK source alongside your own project files, you can do that too. Copy ENSDKResources.bundle and the evernote-sdk-ios folder (in the same folder with ENSDKResources.bundle) into your Xcode project directly. Add the new files to your app target.

### Link with frameworks

evernote-sdk-ios depends on a couple system frameworks, so you'll need to add them to any target's "Link Binary With Libraries" Build Phase. Add the following frameworks in the "Link Binary With Libraries" phase

- MobileCoreServices.framework
- libxml2.dylib

### Modify your application's main plist file

Users will have the fastest OAuth experience in your app if they already have the Evernote app installed. When this is the case, the authentication process will bounce to the Evernote app and authenticate without the user needing to enter their credentials at all. To facilitate this, create an array key called URL types with a single array sub-item called URL Schemes. Give this a single item with your consumer key prefixed with 'en-'

	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string></string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>en-<consumer key></string>
			</array>
		</dict>
	</array>
	
Don't worry: authentication can still proceed if the Evernote app is not installed, but it will fall back to web-based OAuth. This is transparent to your app.

**Note** When your app is in development and uses the "sandbox" environment, authentication will always use web-based OAuth, even if you have the Evernote app installed. After upgrading to a production consumer key, be sure to test authentication again with the Evernote app.

### Add the standard header file to any file that uses the Evernote SDK

    #import <ENSDK/ENSDK.h>

### Modify your AppDelegate

First you set up the `ENSession`, configuring it with your consumer key and secret.

Do something like this in your AppDelegate's `application:didFinishLaunchingWithOptions:` method.

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
		// Initial development is done on the sandbox service
		// When you want to connect to production, just pass "nil" for "optionalHost"
		NSString *SANDBOX_HOST = ENSessionHostSandbox;

		// Fill in the consumer key and secret with the values that you received from Evernote
		// To get an API key, visit http://dev.evernote.com/documentation/cloud/
		NSString *CONSUMER_KEY = @"your key";
		NSString *CONSUMER_SECRET = @"your secret";

		[ENSession setSharedSessionConsumerKey:CONSUMER_KEY
		  						consumerSecret:CONSUMER_SECRET
							      optionalHost:SANDBOX_HOST];
	}

Alternative if you're using a Developer Token (see above) to access *only* your personal, production account: *don't* set a consumer key/secret (or the sandbox environment). Instead, give the SDK your developer token and Note Store URL (both personalized and available from [this page](https://www.evernote.com/api/DeveloperToken.action)). Replace the setup call above with the following.

    [ENSession setSharedSessionDeveloperToken:@"the token string"
                                 noteStoreUrl:@"the url that you got from us"];


Finally, pass through open URL requests via your AppDelegate's `application:openURL:sourceApplication:annotation:` method. If the method doesn't exist, add it.

	- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
		BOOL didHandle = [[ENSession sharedSession] handleOpenURL:url];
		// ...
		return didHandle;
	}

Now you're good to go (and your app will support the fast-path OAuth authentication that will be most effective for your users.)

See it in action
----------------

Before we get into how to work with the simple object model to programmatically interact with Evernote, give it a spin the even easier way:

### Using the Sample App

The SDK comes with a simple sample application, called (shockingly) `EvernoteSDKSample` so you can see the workflow for basic functionality. This is set up as a target within the Xcode project. Building this project will also build the SDK and link to it as a library. This app demonstrates authentication, creating simple notes, web clips, finding and displaying notes, and using the ENSaveToEvernoteActivity subclass of UIActivity (below).

*Note* You will still need to edit the AppDelegate of the sample to include your consumer key and secret. 

### Using the UIActivity subclass (share sheet)

You can let your users send your content into Evernote without building any UI or interacting with the object model at all. You can use the `ENSaveToEvernoteActivity` class when opening the standard iOS activity panel. The SaveToEvernoteActivity knows how to handle items of type NSString and UIImage (and also can handle pre-created ENResource and ENNote objects). This will place an Evernote logo icon in the activity sheet that the user can choose. They'll get a convenient UI for selecting notebook, title, tags, etc. Use the ENSaveToEvernoteActivityDelegate protocol to be notified whether Save to Evernote activity succeeded, just implement the following function:

	- (void)activity:(ENSaveToEvernoteActivity *)activity didFinishWithSuccess:(BOOL)success error:(NSError *)error;
	
Sample code to use ENSaveToEvernoteActivity:

    ENSaveToEvernoteActivity * saveActivity = [[ENSaveToEvernoteActivity alloc] init];
	saveActivity.delegate = self;
    saveActivity.noteTitle = @"Default title";
    NSArray * items = [NSArray arrayWithObject:(self.textView.text)];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:items                                                                              		      
                                                                                      applicationActivities:@[saveActivity]];
    [self presentViewController:activityController animated:YES completion:nil];


Basic Concepts
--------------

### Evernote Concepts

The object model in the SDK is designed to reflect a distilled version of the object model you're familiar with as an Evernote user. The most fundamental object in Evernote is the "note" (represented by an ENNote). A note is one chunk of content visible in a user's account. Its body is stored in a form of markup, and may have attached image or file "resources." A note also has a title, timestamps, tags, and other metadata. 

Notes exist inside of notebooks, and a user has at least one of these in their account. A user can move notes between notebooks using their Evernote client. Users can also join notebooks shared by other users. A user who is also a member of a [Business](http://evernote.com/business/) account will have access to business notebooks that they've created or joined.

The public objects in the SDK generally map to these objects.

### ENNote

An `ENNote` represents the complete set of content within a note (title, body, resources). This object, which you create and populate to upload, or receive as the result of a download operation, doesn't point to any specific note on the service; it's just a container for the content.

An `ENNote` can sport an array of `ENResource` objects that are like file attachments. A note has some content (represented by `ENNoteContent`) that makes up the "body" of the note. You can populate this from plaintext, HTML, etc.

### ENNoteRef

On the other hand, an `ENNoteRef` is an immutable, opaque reference to a specific note that exists on the service, in a user's account. When you upload an `ENNote`, you'll receive an `ENNoteRef` in response that points to the resulting service object. This object has convenience functions to serialize and deserialize it if you'd like to store it to access that service note at a later date.

### ENNotebook

An `ENNotebook` represents a notebook on the service. It has several properties that can tell you its name, business or sharing status, etc. 

### ENSession

The `ENSession` singleton (accessible via `-sharedSession`) is the primary "interface" with the SDK. You'll use the session to authenticate a user with the service, and the session exposes the methods you'll use to perform Evernote operations.

Using the Evernote SDK
----------------------

### Authenticate

When the session starts up, if it's not already authenticated, you'll need to authenticate the `ENSession`, passing in your view controller.

A typical place to do this would be a "link to Evernote" button action.

    ENSession *session = [ENSession sharedSession];
    [session authenticateWithViewController:self completion:^(NSError *error) {
        if (error) {
            // authentication failed 
            // show an alert, etc
            // ...
        } else {
            // authentication succeeded 
            // do something now that we're authenticated
            // ...
        }
    }];

Calling `-authenticateWithViewController:completion:` will start the OAuth process. ENSession will open a new modal view controller (or bounce to an installed Evernote app if applicable) to display Evernote's OAuth web page and handle all the back-and-forth OAuth handshaking. When the user finishes this process, Evernote's modal view controller will be dismissed.

Authentication credentials are saved on the device once the user grants access, so this step is only necessary as part of an explicit linking. Subsequent access to the shared session will automatically restore the existing session for you. You can ask a session if it's already authenticated using the `-isAuthenticated` property.

N.B. The SDK supports switching between authentication environments to the Yinxiang Biji (Evernote China) service transparently. Please make sure your consumer key has been [activated](http://dev.evernote.com/support/) for the China service before you deploy or test with the China service.

### Adding Resources

We saw at the beginning in "Hello World!" how you'd create a new, plaintext note and upload it to the user's default notebook. Let's say you'd like to create a note with an image that you have. That's easy too. You just need to create an `ENResource` that represents the image data, and add it to the note before uploading:

	ENNote * note = [[ENNote alloc] init];
	note.content = [ENNoteContent noteContentWithString:@"Check out this awesome picture!"];
	note.title = @"My Image Note";
	ENResource * resource = [[ENResource alloc] initWithImage:myImage]; // myImage is a UIImage object.
	[note addResource:resource];
	[[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef * noteRef, NSError * uploadNoteError) {
		// same as above...
	}];

You aren't restricted to images; you can use any kind of file. Just use the appropriate initializer for `ENResource`. You'll need to know the data's MIME type to pass along.

### Creating a note using HTML or web content.

The SDK contains a facility for capturing web content as a note. This content can be remote of course (generated by your service) or could be loaded locally from resources within your app. You can use `+[ENNote populateNoteFromWebView:completion:]` to create an `ENNote` object from the contents of a loaded `UIWebView` object. 

    [ENNote populateNoteFromWebView:webView completion:^(ENNote * note) {
	    if (note) {
		    [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
	            // etc...
            }];
        }
    }];  

This method will capture content from the DOM. Images in the page will be captured as ENResource objects in the note (not true of images provided as CSS styles.) Please note that this is not a comprehensive "web clipper", though, and isn't designed to work fully on arbitrary pages from the internet. It will work best on pages which have been generally designed for the purpose of being captured as note content. 

If your app doesn't already have your content into visible web views, you can always create an offscreen `UIWebView` and populate a note from it once loaded. When doing this, please bear in mind that the dimensions of the web view (even when offscreen) can affect the rendered contents. Also note that `UIWebView`'s delegate methods don't indicate when the whole page has "completely" loaded if your page includes linked (remote) resources. 

### Downloading and displaying an existing note

If you have an `ENNoteRef` object, either because you uploaded a note and kept the resulting note ref, or because you got one from a `findNotes..` operation (below), you can download the content of that note from the service like this (`progress` optionally sets a block that gets status updates during download):

    [[ENSession sharedSession] downloadNote:noteRef progress:nil completion:^(ENNote * note, NSError * error) {
		if (note) {
			// success.
		}
	}];
	
But what can you do with a note? Well, you could change parts of the object, and reupload it to e.g. replace the existing note on the service. (See the documentation for `uploadNote...`). But you can also display it to the user. We've made this easy-- rather than serializing it to HTML and fussing with attached image resources, we've provided a method to generate a single Safari "web archive" from the note; this is a bundled data type which `UIWebView` natively knows how to load directly. Let's say you have a `UIWebView` ready to go, called `webView`:

    [note generateWebArchiveData:^(NSData *data) {
    	[webView loadData:data MIMEType:ENWebArchiveDataMIMEType textEncodingName:nil baseURL:nil];
	}];

This generates the web archive and hands it to the web view. (The generation is asynchronous, but is immediate.) Note that the provided constant `ENWebArchiveDataMIMEType` has the MIME type for this special kind of data.

### Finding notes in Evernote

The SDK provides a simplified search operation that can find notes available to the user. Use an `ENNoteSearch` to encapsulate a query. (There are a few basic search objects you can use, or create your own with anything valid in the [Evernote search grammar](https://dev.evernote.com/doc/articles/search_grammar.php)). For example, to search for the 20 most recent notes containing the word "redwood", you could use search like this:

	[[ENSession sharedSession] findNotesWithSearch:[ENNoteSearch noteSearchWithSearchString:@"redwood"]
										inNotebook:nil
										   orScope:ENSessionSearchScopeDefault
										 sortOrder:ENSessionSortOrderRecentlyCreated
										maxResults:20
										completion:^(NSArray * findNotesResults, NSError * findNotesError) {
		if (findNotesResults) {
			for (ENSessionFindNotesResult * result in findNotesResults) {
				// Each ENSessionFindNotesResult has a noteRef along with other important metadata.
				NSLog(@"Found note with title: %@", result.title);
			}
		}
	}];

If you specify a notebook, the search will be limited to that notebook. If you omit the notebook, you can specify different combinations of search scope (personal, business, shared notebooks, etc), but please be aware of performance considerations. 

**Performance Warning** Doing a broadly scoped search, and/or specifying a very high number of max results against a user's account with significant content can result in slow responses and a poor user experience. If the number of results is unbounded, the client may run out of memory and be terminated if there are too many results! Business scope in particular can produce an unpredictable amount of results. Please consider your usage very carefully here. You can do paged searches, and have other low-level controls by [using the advanced API.](Working_with_the_Advanced_\(EDAM\)_API.md)

### What else can I do?

Other things ENSession can do for you is enumerate all notebooks a user has access to, replace/update existing notes, search and download notes, and fetch thumbnails. You should be able to get started with what's in the headers, starting with `ENSession.h`.

If you want to do more sophisticated work with Evernote, the primary interface that this SDK provides may not offer all of the functionality that you need. There is a lower-level API available that exposes the full breadth of the service capabilities at the expense of some learning overhead. [Have a look at this guide to advanced functionality to get started with it.](Working_with_the_Advanced_\(EDAM\)_API.md)

 

