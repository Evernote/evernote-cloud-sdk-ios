/*
 * Copyright (c) 2012-2014 by Evernote Corporation, All rights reserved.
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

#import "ENOAuthViewController.h"
#import "ENSDKPrivate.h"

@interface ENOAuthViewController() <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *authorizationURL;
@property (nonatomic, strong) NSString *oauthCallbackPrefix;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString* currentProfileName;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL isSwitchingAllowed;

@end

@implementation ENOAuthViewController

@synthesize delegate = _delegate;
@synthesize authorizationURL = _authorizationURL;
@synthesize oauthCallbackPrefix = _oauthCallbackPrefix;
@synthesize webView = _webView;

- (void)dealloc
{
    self.delegate = nil;
    self.webView.delegate = nil;
    [self.webView stopLoading];
}

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL 
           oauthCallbackPrefix:(NSString *)oauthCallbackPrefix
                   profileName:(NSString *)currentProfileName
                allowSwitching:(BOOL)isSwitchingAllowed
                      delegate:(id<ENOAuthViewControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.authorizationURL = authorizationURL;
        self.oauthCallbackPrefix = oauthCallbackPrefix;
        self.currentProfileName = currentProfileName;
        self.delegate = delegate;
        self.isSwitchingAllowed = isSwitchingAllowed;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel:)];
        
    self.navigationItem.rightBarButtonItem = cancelItem;
    
    // adding an activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator setHidesWhenStopped:YES];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    self.activityIndicator.frame = CGRectMake((self.navigationController.view.frame.size.width - (self.activityIndicator.frame.size.width/2))/2,
                                              (self.navigationController.view.frame.size.height - (self.activityIndicator.frame.size.height/2) - 44)/2,
                                              self.activityIndicator.frame.size.width,
                                              self.activityIndicator.frame.size.height);
    [self.webView addSubview:self.activityIndicator];
    [self updateUIForNewProfile:self.currentProfileName
           withAuthorizationURL:self.authorizationURL];
}

- (void)cancel:(id)sender
{
    [self.webView stopLoading];
    if (self.delegate) {
        [self.delegate oauthViewControllerDidCancel:self];
    }
    self.delegate = nil;
}

- (void)switchProfile:(id)sender
{
    [self.webView stopLoading];
    // start a page flip animation 
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                           forView:[[self navigationController] view]
                             cache:YES];
    [self.webView setDelegate:nil];
    // Blank out the web view
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"];
    self.navigationItem.leftBarButtonItem = nil;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [self.activityIndicator startAnimating];
    [self.delegate oauthViewControllerDidSwitchProfile:self];
}

- (void)updateUIForNewProfile:(NSString*)newProfile withAuthorizationURL:(NSURL*)authURL{
    self.authorizationURL = authURL;
    self.currentProfileName = newProfile;
    if(self.isSwitchingAllowed) {
        NSString *leftButtonTitle = nil;
        if([self.currentProfileName isEqualToString:ENBootstrapProfileNameChina]) {
            leftButtonTitle = ENSDKLocalizedString(@"Evernote-International", @"Evernote-International");
        }
        else {
            leftButtonTitle = ENSDKLocalizedString(@"Evernote-China", @"Evernote-China");
        }
        UIBarButtonItem* switchProfileButton = [[UIBarButtonItem alloc] initWithTitle:leftButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(switchProfile:)];
        self.navigationItem.leftBarButtonItem = switchProfileButton;
    }
    [self loadWebView];
}

- (void)loadWebView {
    [self.activityIndicator startAnimating];
    [self.webView setDelegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.authorizationURL]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

# pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        // ignore "Frame load interrupted" errors, which we get as part of the final oauth callback :P
        return;
    }
    
    if (error.code == NSURLErrorCancelled) {
        // ignore rapid repeated clicking (error code -999)
        return;
    }
    
    [self.webView stopLoading];

    if (self.delegate) {
        [self.delegate oauthViewController:self didFailWithError:error];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] hasPrefix:self.oauthCallbackPrefix]) {
        // this is our OAuth callback prefix, so let the delegate handle it
        if (self.delegate) {
            [self.delegate oauthViewController:self receivedOAuthCallbackURL:request.URL];
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityIndicator stopAnimating];
}

@end
