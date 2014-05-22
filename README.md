Evernote Cloud SDK for iOS version 2.0 (beta)
======================================

What this is
------------
A simple, workflow-oriented library built on the Evernote Cloud API. It's designed to drop into your app easily and make the most common tasks very simple to accomplish. It is also the (eventual) successor to the evernote-ios-sdk library, although while this library has beta status, that one is still available and supported.

Installing
----------

### Register for an Evernote API key (and secret)...

You can do this on the [Evernote Developers portal page](http://dev.evernote.com/documentation/cloud/). Most applications will want to do this-- it's easy and instant.

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

Users will have the fastest OAuth experience in your app if they already have the Evernote app installed. To facilitate this, create an array key called URL types with a single array sub-item called URL Schemes. Give this a single item with your consumer key prefixed with 'en-'

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


Finally, do something like this in your AppDelegate's `application:openURL:sourceApplication:annotation:` method. If the method doesn't exist, add it.

	- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
		BOOL didHandle = [[ENSession sharedSession] handleOpenURL:url];
		// ...
		return didHandle;
	}

Now you're good to go.

N.B. The SDK supports switching between environments to the Yinxiang Biji (Evernote China) service transparently. Please make sure your consumer key has been [activated](http://dev.evernote.com/support/) for the China service before you deploy or test with the China service.

Using the Sample App
--------------------

The SDK comes with a simple sample application, called (shockingly) `EvernoteSDKSample` so you can see the workflow for basic functionality. This is set up as a target within the Xcode project. Building this project will also build the SDK and link to it as a library. This app demonstrates authentication, creating simple notes, web clips, and using the ENSaveToEvernoteActivity subclass of UIActivity (below).

*Note* You will still need to edit the AppDelegate of the sample to include your consumer key and secret. 

Using the Evernote SDK
----------------------

### Authenticate

When the session starts up, if it's not already authenticated, you'll need to authenticate the `ENSession`, passing in your view controller.

A normal place to do this would be a "link to Evernote" button action.

    ENSession *session = [ENSession sharedSession];
    [session authenticateWithViewController:self completion:^(NSError *error) {
        if (error) {
            // authentication failed :(
            // show an alert, etc
            // ...
        } else {
            // authentication succeeded :)
            // do something now that we're authenticated
            // ...
        }
    }];

Calling `-authenticateWithViewController:completion:` will start the OAuth process. ENSession will open a new modal view controller (or bounce to an installed Evernote app if applicable) to display Evernote's OAuth web page and handle all the back-and-forth OAuth handshaking. When the user finishes this process, Evernote's modal view controller will be dismissed.

Authentication credentials are saved on the device once the user grants access, so this step is only necessary as part of an explicit linking. Subsequent access to the shared session will automatically restore the existing session for you. You can ask a session if it's already authenticated using the `-isAuthenticated` property.

### Hello, world.

To create a new note with no user interface, you can just do this:

    ENNote * note = [[ENNote alloc] init];
	note.content = [ENNoteContent noteContentWithString:@"Hello, World!"];
	note.title = @"My First Note";
    [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef * noteRef, NSError * uploadNoteError) {
		if (noteRef) {
			// It worked! You can use this note ref to share the note or otherwise find it again.
			...
		} else {
			NSLog(@"Couldn't upload note. Error: %@", uploadNoteError);
		}
	}];

This creates a new, plaintext note, with a title, and uploads it to the user's default notebook.

### Adding Resources

Let's say you'd like to create a note with an image that you have. That's easy too. You just need to create an `ENResource` that represents the image data, and attach it to the note before uploading:

	ENNote * note = [[ENNote alloc] init];
	note.content = [ENNoteContent noteContentWithString:@"Check out this awesome picture!"];
	note.title = @"My Image Note";
	ENResource * resource = [[ENResource alloc] initWithImage:myImage]; // myImage is a UIImage object.
	[note addResource:resource]
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

### Using the UIActivity subclass (share sheet)

Want a simple way of sending content to Evernote without building any UI yourself? We've got it for you. You can use the `ENSaveToEvernoteActivity` class when opening the standard iOS activity panel. The SaveToEvernoteActivity knows how to handle items of type NSString and UIImage (and also can handle pre-created ENResource and ENNote objects). This will place an Evernote logo icon in the activity sheet that the user can choose. They'll get a convenient UI for selecting notebook, title, tags, etc. Use the ENSaveToEvernoteActivityDelegate protocol to be notified whether Save to Evernote activity succeeded, just implement the following function:

	- (void)activity:(ENSaveToEvernoteActivity *)activity didFinishWithSuccess:(BOOL)success error:(NSError *)error;
	
Sample code to use ENSaveToEvernoteActivity:

    ENSaveToEvernoteActivity * saveActivity = [[ENSaveToEvernoteActivity alloc] init];
	saveActivity.delegate = self;
    saveActivity.noteTitle = @"Default title";
    NSArray * items = [NSArray arrayWithObject:(self.textView.text)];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:items                                                                              		      
                                                                                      applicationActivities:@[saveActivity]];
    [self presentViewController:activityController animated:YES completion:nil];


### What else is in here?

The high level functions include those on `ENSession`, and you can look at `ENNote`, `ENResource`, `ENNotebook` for simple models of these objects as well. Other things ENSession can do for you is enumerate all notebooks a user has access to, replace/update existing notes, search and download notes, and fetch thumbnails. Documentation/guides for these functions is still in the works, but you should be able to get started with what's in the headers, starting with `ENSession.h`.

See below for some initial notes on supporting even more advanced functionality via including the "Advanced" header and using the full EDAM layer.

FAQ
---

### What iOS versions are supported?

This version of the SDK is designed for iOS 7 (and above). 

### Does the Evernote SDK support ARC?

Yes. (To use the SDK in a non-ARC project, please use the -fobjc-arc compiler flag on all the files in the Evernote SDK.)

### Evernote can do lots of things that aren't available in ENSession. How can I do more?

ENSession is an intentionally general, workflow-oriented abstraction layer. It's currently optimized for the creation and upload of new notes, and simple search/download of existing notes. Evernote can do a lot more, though, and you can get closer to the metal, but it will require a fair bit of understanding of Evernote's object model and API.

First off, import `<ENSDK/Advanced/ENSDKAdvanced.h>` instead of `ENSDK.h`. Then ask an authenticated session for its `-primaryNoteStore`. You can look at the header for `ENNoteStoreClient` to see all the methods offered on it, with block-based completion parameters. You won't generally be able to use any of the "EN"-prefixed objects in this world; you're at the "EDAM" layer, which are the actual objects that the Evernote service works with. These are powerful but somewhat complex; [please see the full API documentation for information on what you are able to do](http://dev.evernote.com/doc/reference/).

This "primary" note store client can only interact with a user's personal account, and won't work with a user's business data or shared notebook data directly; you can get note store clients for those destinations by asking for `-businessNoteStore` and `-noteStoreForLinkedNotebook:`  

### My app uses an App Notebook. Do I need to do anything special?

In general, no. ENSession will simply return only a single notebook if you `listNotebooks` (unless the user has deleted your app notebook, in which case it will have no results). New notes created in a default (`nil`) notebook will go into your App Notebook.

*Please Note*: ENSession knows how to handle a user selecting any available notebook (including a linked or business notebook) for its App Notebook. However, if you are using the "advanced" functions in the SDK and dropping down to the EDAM layer, you'll need to be aware of the intricacies of managing talking to a linked notebook. But you can opt-out of allowing users to pick a linked notebook, by simply setting 

    [[ENSession sharedSession].supportsLinkedAppNotebook = NO

as part of your setup, prior to authenticating a user. Our advice is usually to opt out of this unless you are really conversant in the API, but feel free to get in touch for more info.

### Where can I find out more about the Evernote service, API, and object model for my more sophisticated integration?

Please check out the [Evernote Developers portal page](http://dev.evernote.com/documentation/cloud/).

Please also see the [complete cloud API documentation](http://dev.evernote.com/doc/reference/)