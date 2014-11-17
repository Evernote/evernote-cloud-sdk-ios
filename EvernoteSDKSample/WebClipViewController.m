//
//  WebClipViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "WebClipViewController.h"
#import <ENSDK/ENSDK.h>
#import "SVProgressHUD.h"
#import "CommonUtils.h"

@interface WebClipViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation WebClipViewController

- (void)loadView {
    [super loadView];
    self.backgroundView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.backgroundView];
    
    CGRect frame = self.backgroundView.bounds;
    CGRect labelFrame, keywordFrame;
    CGRectDivide(frame, &labelFrame, &frame, 44.0, CGRectMinYEdge);
    CGRectDivide(frame, &keywordFrame, &frame, 44.0, CGRectMinYEdge);
    
    self.instructionLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [self.instructionLabel setText:@"Please specify the URL to clip"];
    [self.instructionLabel setTextAlignment:NSTextAlignmentCenter];
    [self.backgroundView addSubview:self.instructionLabel];
    
    self.urlField = [[UITextField alloc] initWithFrame:keywordFrame];
    [self.urlField setText:@"https://developer.apple.com/xcode/"];
    [self.urlField setTextAlignment:NSTextAlignmentCenter];
    [self.backgroundView addSubview:self.urlField];
    
    [self.navigationItem setTitle:@"Clip web page"];
    UIBarButtonItem *clipItem = [[UIBarButtonItem alloc] initWithTitle:@"Clip" style:UIBarButtonItemStylePlain target:self action:@selector(loadWebView)];
    self.navigationItem.rightBarButtonItem = clipItem;
}

- (void)loadWebView {
    NSURL *urlToClip = [NSURL URLWithString:self.urlField.text];
    if (urlToClip == nil) {
        [CommonUtils showSimpleAlertWithMessage:@"URL not valid"];
        return;
    }
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.window.bounds];
    self.webView.delegate = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [self.webView loadRequest:[NSURLRequest requestWithURL:urlToClip]];
}

- (void)clipWebPage {
    UIWebView * webView = self.webView;
    self.webView.delegate = nil;
    [self.webView stopLoading];
    self.webView = nil;
    
    [ENNote populateNoteFromWebView:webView completion:^(ENNote * note) {
        if (!note) {
            [self finishClip];
            return;
        }
        [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
            NSString * message = nil;
            if (noteRef) {
                message = @"Web note created.";
            } else {
                message = @"Failed to create web note.";
            }
            [self finishClip];
            [CommonUtils showSimpleAlertWithMessage:message];
        }];
    }];
}

- (void)finishClip
{
    [SVProgressHUD dismiss];
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    NSLog(@"Web view fail: %@", error);
    self.webView = nil;
    [self finishClip];
    [CommonUtils showSimpleAlertWithMessage:@"Failed to load web page to clip."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // At the end of every load complete, cancel a pending perform and start a new one. We wait for 3
    // seconds for the page to "settle down"
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    [self performSelector:@selector(clipWebPage) withObject:nil afterDelay:3.0];
}

@end
