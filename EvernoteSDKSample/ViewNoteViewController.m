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
    
    //Make CSS Button for file link
    NSString *css = @"a.btn{-webkit-border-radius: 50;    -moz-border-radius: 50;    border-radius: 50px;    font-family: Arial;color: #007bff;    font-size: 24px;background: #ffffff;padding: 10px 60px 10px 60px;border: solid #007bff 6px;    text-decoration: none;}";
    NSMutableString *javascript = [NSMutableString string];
    [javascript appendString:@"var style = document.createElement('style');"];
    [javascript appendString:@"style.type = 'text/css';"];
    [javascript appendFormat:@"var cssContent = document.createTextNode('%@');", css];
    [javascript appendString:@"style.appendChild(cssContent);"];
    [javascript appendString:@"document.body.appendChild(style);"];
    [webView stringByEvaluatingJavaScriptFromString:javascript];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    if ([request.URL.scheme isEqualToString:@"file"] && [request.URL.pathExtension isEqualToString:@"pdf"]) {
        return YES;
    }
    // Don't allow user to navigate from here.
    return !self.doneLoading;
}
@end
