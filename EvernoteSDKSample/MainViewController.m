//
//  ViewController.m
//  EvernoteSDKSample
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "MainViewController.h"
#import <ENSDK/ENSDK.h>
#import "UserInfoViewController.h"
#import "TagsInfoViewController.h"
#import "SaveActivityViewController.h"
#import "SearchNotesViewController.h"
#import "NotebooksViewController.h"
#import "SVProgressHUD.h"
#import "CommonUtils.h"

#define PHOTO_MAX_WIDTH 500

NS_ENUM(NSInteger, SampleFunctions) {
    kSampleFunctionsUserInfo,
    kSampleFunctionsTagsInfo,
    kSampleFunctionsSaveActivity,
    kSampleFunctionsCreatePhotoNote,
    kSampleFunctionsClipWebPage,
    kSampleFunctionsSearchNotes,
    kSampleFunctionsViewMyNotes,
    
    kSampleFunctionsMaxValue
};

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIWebViewDelegate>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) UIWebView * webView;
@property (nonatomic, strong) UIBarButtonItem * loginItem;
@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
    
    self.loginItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleDone target:self action:@selector(logInOrLogOut)];
    self.navigationItem.rightBarButtonItem = self.loginItem;
}

- (void)updateLoginItem {
    BOOL loggedIn = [[ENSession sharedSession] isAuthenticated];
    [self.loginItem setTitle:(loggedIn? @"Logout" : @"Login")];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:NULL];
    [self.navigationItem setBackBarButtonItem:backButton];
    [self update];
}

- (void)update
{
    if ([[ENSession sharedSession] isAuthenticated]) {
        [self.navigationItem setTitle:[[ENSession sharedSession] userDisplayName]];
    } else {
        [self.navigationItem setTitle:nil];
    }
    [self updateLoginItem];
    
    [self.tableView reloadData];
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
        return 0; // Authenticate
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    switch (indexPath.row) {
        case kSampleFunctionsUserInfo:
            cell.textLabel.text = @"User info";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsTagsInfo:
            cell.textLabel.text = @"Tags";
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
            
        case kSampleFunctionsSearchNotes:
            cell.textLabel.text = @"Search notes via keyword";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsViewMyNotes:
            cell.textLabel.text = @"View my notes";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        default:
            NSAssert(0, @"indexPath not valid");
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case kSampleFunctionsUserInfo:
        {
            UIViewController * vc = [[UserInfoViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case kSampleFunctionsTagsInfo:
        {
            UIViewController * vc = [[TagsInfoViewController alloc] init];
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
            [self createPhotoNoteIfAvailable];
            break;
        }
        case kSampleFunctionsClipWebPage:
        {
            [self showAlertToClipWebPage];
            break;
        }
        case kSampleFunctionsSearchNotes:
        {
            SearchNotesViewController * searchVC = [[SearchNotesViewController alloc] init];
            [self.navigationController pushViewController:searchVC animated:YES];
            break;
        }
        case kSampleFunctionsViewMyNotes:
        {
            NotebooksViewController * notebooksVC = [[NotebooksViewController alloc] init];
            [self.navigationController pushViewController:notebooksVC animated:YES];
            break;
        }
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)logInOrLogOut {
    if ([[ENSession sharedSession] isAuthenticated]) {
        [[ENSession sharedSession] unauthenticate];
        [self update];
    } else {
        [[ENSession sharedSession] authenticateWithViewController:self
                                               preferRegistration:NO
                                                       completion:^(NSError *authenticateError) {
                                                           if (!authenticateError) {
                                                               [self update];
                                                           } else if (authenticateError.code != ENErrorCodeCancelled) {
                                                               [CommonUtils showSimpleAlertWithMessage:@"Could not authenticate."];
                                                           }
                                                       }];
    }
}

- (void)createPhotoNoteIfAvailable {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController * picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma - Web Clipping

- (void)showAlertToClipWebPage {
    UIAlertController *clipController = [UIAlertController alertControllerWithTitle:@"Please enter the URL:" message:@"The web page with the URL will be saved in Evernote" preferredStyle:UIAlertControllerStyleAlert];
    [clipController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = @"https://evernote.com/products/scannable/";
        [textField setKeyboardType:UIKeyboardTypeURL];
    }];
    UIAlertAction *clipAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *urlField = clipController.textFields[0];
        NSString *urlString = urlField.text;
        [self loadWebViewWithURLString:urlString];
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [clipController addAction:clipAction];
    [clipController addAction:dismissAction];
    [self presentViewController:clipController animated:YES completion:nil];
}

- (void)loadWebViewWithURLString:(NSString *)urlString {
    NSURL *urlToClip = [NSURL URLWithString:urlString];
    if (urlToClip == nil) {
        [CommonUtils showSimpleAlertWithMessage:@"URL not valid"];
        return;
    }
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.window.bounds];
    self.webView.delegate = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
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

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Normalize image orientation if it's from the camera and scale it down.
    CGFloat scaleFactor = image.size.width / PHOTO_MAX_WIDTH;
    CGSize targetSize = CGSizeMake(image.size.width / scaleFactor, image.size.height / scaleFactor);
    UIGraphicsBeginImageContext(targetSize);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Build note with resource.
    ENResource * resource = [[ENResource alloc] initWithImage:image];
    ENNote * note = [[ENNote alloc] init];
    note.title = @"Photo note";
    [note addResource:resource];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
        NSString * message = nil;
        if (noteRef) {
            message = @"Photo note created.";
        } else {
            message = @"Failed to create photo note.";
        }
        [SVProgressHUD dismiss];
        [CommonUtils showSimpleAlertWithMessage:message];
    }];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
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
