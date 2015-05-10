//
//  ViewNoteViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 5/22/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "NoteDetailViewController.h"
#import "ResourcesListTableViewController.h"
#import "SVProgressHUD.h"
#import "CommonUtils.h"

@interface NoteDetailViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView * webView;
@property (nonatomic, assign) BOOL doneLoading;
@property (nonatomic, strong) ENNote *note;
@end

@implementation NoteDetailViewController

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
    
    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    self.navigationItem.rightBarButtonItem = menuItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SVProgressHUD showProgress:0.0 status:nil maskType:SVProgressHUDMaskTypeBlack];
    [[ENSession sharedSession] downloadNote:self.noteRef progress:^(CGFloat progress) {
        if (self.webView) {
            [SVProgressHUD showProgress:progress];
        }
    } completion:^(ENNote *note, NSError *downloadNoteError) {
        if (note && self.webView) {
            self.note = note;
            [self loadWebDataFromNote:note];
        } else {
            NSLog(@"Error downloading note contents %@", downloadNoteError);
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (void)showMenu {
    UIAlertController *menuController = [[UIAlertController alloc] init];
    [menuController addAction:[UIAlertAction actionWithTitle:@"View Resources" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        ResourcesListTableViewController *vc = [[ResourcesListTableViewController alloc] initWithNote:self.note noteRef:self.noteRef];
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [menuController addAction:[UIAlertAction actionWithTitle:@"View this note in Evernote" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self viewInEvernote];
    }]];
    [self presentViewController:menuController animated:YES completion:nil];
}

- (void)viewInEvernote {
    BOOL result = [[ENSession sharedSession] viewNoteInEvernote:self.noteRef];
    if (result == NO) {
        [CommonUtils showSimpleAlertWithMessage:@"Evernote App not installed"];
    }
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
