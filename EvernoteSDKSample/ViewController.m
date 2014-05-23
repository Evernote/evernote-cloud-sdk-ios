//
//  ViewController.m
//  EvernoteSDKSample
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "ViewController.h"
#import <ENSDK/ENSDK.h>
#import "UserInfoViewController.h"
#import "SaveActivityViewController.h"
#import "ViewAppNotesViewController.h"
#import "SVProgressHUD.h"

NS_ENUM(NSInteger, SampleFunctions) {
    kSampleFunctionsUnauthenticate,
    kSampleFunctionsUserInfo,
    kSampleFunctionsSaveActivity,
    kSampleFunctionsCreatePhotoNote,
    kSampleFunctionsClipWebPage,
    kSampleFunctionsViewAppNotesList,
    
    kSampleFunctionsMaxValue
};

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIWebViewDelegate>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) UIWebView * webView;
@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:NULL];
    [self.navigationItem setBackBarButtonItem:backButton];
    [self update];
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.7]];
}

- (void)update
{
    [self.tableView reloadData];
    if ([[ENSession sharedSession] isAuthenticated]) {
        [self.navigationItem setTitle:[[ENSession sharedSession] userDisplayName]];
    } else {
        [self.navigationItem setTitle:nil];
    }
}

- (void)showSimpleAlertWithMessage:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[ENSession sharedSession] isAuthenticated]) {
        return kSampleFunctionsMaxValue;
    } else {
        return 1; // Authenticate
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    switch (indexPath.row) {
        case kSampleFunctionsUnauthenticate:
            if ([[ENSession sharedSession] isAuthenticated]) {
                cell.textLabel.text = @"Unauthenticate";
            } else {
                cell.textLabel.text = @"Authenticate";
            }
            break;
            
        case kSampleFunctionsUserInfo:
            cell.textLabel.text = @"User info";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsSaveActivity:
            cell.textLabel.text = @"Save Activity";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsCreatePhotoNote:
            cell.textLabel.text = @"Create photo note";
            break;
            
        case kSampleFunctionsClipWebPage:
            cell.textLabel.text = @"Clip web page";
            break;
            
        case kSampleFunctionsViewAppNotesList:
            cell.textLabel.text = @"View this app's notes";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
        default:
            ;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case kSampleFunctionsUnauthenticate:
            if ([[ENSession sharedSession] isAuthenticated]) {
                [[ENSession sharedSession] unauthenticate];
                [self update];
            } else {
                [[ENSession sharedSession] authenticateWithViewController:self completion:^(NSError *authenticateError) {
                    if (!authenticateError) {
                        [self update];
                    } else if (authenticateError.code != ENErrorCodeCancelled) {
                        [self showSimpleAlertWithMessage:@"Could not authenticate."];
                    }
                }];
            }
            break;
            
        case kSampleFunctionsUserInfo:
        {
            UIViewController * vc = [[UserInfoViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case kSampleFunctionsSaveActivity:
        {
            UIViewController * vc = [[SaveActivityViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case kSampleFunctionsCreatePhotoNote:
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.delegate = self;
                [self presentViewController:picker animated:YES completion:nil];
            }
            break;
        }
        case kSampleFunctionsClipWebPage:
        {
            self.webView = [[UIWebView alloc] initWithFrame:self.view.window.bounds];
            self.webView.delegate = self;
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.theatlantic.com/technology/print/2014/04/exploding-whales/361444/"]]];
            break;
        }
        case kSampleFunctionsViewAppNotesList:
        {
            ViewAppNotesViewController * vanvc = [[ViewAppNotesViewController alloc] init];
            [self.navigationController pushViewController:vanvc animated:YES];
            break;
        }
        default:
            ;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)clipWebView
{
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
            [self showSimpleAlertWithMessage:message];
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebView) object:nil];
    NSLog(@"Web view fail: %@", error);
    self.webView = nil;
    [self finishClip];
    [self showSimpleAlertWithMessage:@"Failed to load web page to clip."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // At the end of every load complete, cancel a pending perform and start a new one. We wait for 3
    // seconds for the page to "settle down"
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebView) object:nil];
    [self performSelector:@selector(clipWebView) withObject:nil afterDelay:3.0];
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    ENResource * resource = [[ENResource alloc] initWithImage:image];
    ENNote * note = [[ENNote alloc] init];
    note.title = @"Photo note";
    [note addResource:resource];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
        NSString * message = nil;
        if (noteRef) {
            message = @"Photo note created.";
        } else {
            message = @"Failed to create photo note.";
        }
        [SVProgressHUD dismiss];
        [self showSimpleAlertWithMessage:message];
    }];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
