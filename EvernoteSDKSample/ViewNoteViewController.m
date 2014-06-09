//
//  ViewNoteViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 5/22/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "ViewNoteViewController.h"
#import "SVProgressHUD.h"

@interface ViewNoteViewController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView * webView;
@property (nonatomic, assign) BOOL doneLoading;
@end

@implementation ViewNoteViewController

- (void)loadView
{
    [super loadView];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.noteTitle;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SVProgressHUD showProgress:0.0 status:nil maskType:SVProgressHUDMaskTypeClear];
    [[ENSession sharedSession] downloadNote:self.noteRef progress:^(CGFloat progress) {
        if (self.webView) {
            [SVProgressHUD showProgress:progress];
        }
    } completion:^(ENNote *note, NSError *downloadNoteError) {
        if (note && self.webView) {
            [self loadWebDataFromNote:note];
        } else {
            NSLog(@"Error downloading note contents %@", downloadNoteError);
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.webView = nil;
    [SVProgressHUD dismiss];
}

- (void)loadWebDataFromNote:(ENNote *)note
{
    [note generateWebArchiveData:^(NSData *data) {
        [SVProgressHUD dismiss];
        [self.webView loadData:data
                      MIMEType:ENWebArchiveDataMIMEType
              textEncodingName:nil
                       baseURL:nil];
    }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.doneLoading = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    // Don't allow user to navigate from here.
    return !self.doneLoading;
}
@end
