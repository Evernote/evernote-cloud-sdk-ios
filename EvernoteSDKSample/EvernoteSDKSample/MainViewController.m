//
//  ViewController.m
//  EvernoteSDKSample
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "MainViewController.h"
#import <EvernoteSDK/EvernoteSDK.h>
#import "UserInfoViewController.h"
#import "TagsInfoViewController.h"
#import "SaveActivityViewController.h"
#import "NotebooksViewController.h"
#import "NoteListResultViewController.h"
#import "SVProgressHUD.h"
#import "CommonUtils.h"

#define PHOTO_MAX_WIDTH 500

NS_ENUM(NSInteger, SampleFunctions) {
    kSampleFunctionsSaveActivity,
    kSampleFunctionsUserInfo,
    kSampleFunctionsTagsInfo,
    kSampleFunctionsCreatePhotoNote,
    kSampleFunctionsClipWebPage,
    kSampleFunctionsSearchNotes,
    kSampleFunctionsViewMyNotes,
    kSampleFunctionsCustomizeNote,
    
    kSampleFunctionsMaxValue
};

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,WKNavigationDelegate>

@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) WKWebView * webView;
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
    [self.loginItem setTitle:(loggedIn? NSLocalizedString(@"Logout", @"Logout"): NSLocalizedString(@"Login", @"Login"))];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back") style:UIBarButtonItemStylePlain target:nil action:NULL];
    [self.navigationItem setBackBarButtonItem:backButton];
    [self update];
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.7]];
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
        return 1; // Authenticate
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    switch (indexPath.row) {
        case kSampleFunctionsUserInfo:
            cell.textLabel.text = NSLocalizedString(@"User info", @"User info");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsTagsInfo:
            cell.textLabel.text = NSLocalizedString(@"Tags", @"Tags");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsSaveActivity:
            cell.textLabel.text = NSLocalizedString(@"Save Activity", @"Save Activity");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case kSampleFunctionsCreatePhotoNote:
            cell.textLabel.text = NSLocalizedString(@"Create photo note", @"Create photo note");
            break;
            
        case kSampleFunctionsClipWebPage:
            cell.textLabel.text = NSLocalizedString(@"Clip web page", @"Clip web page");
            break;
            
        case kSampleFunctionsSearchNotes:
            cell.textLabel.text = NSLocalizedString(@"Search notes via keyword", @"Search notes via keyword");
            break;
            
        case kSampleFunctionsViewMyNotes:
            cell.textLabel.text = NSLocalizedString(@"View my notes", @"View my notes");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        
        case kSampleFunctionsCustomizeNote:
            cell.textLabel.text = NSLocalizedString(@"Save a customized note", @"Save a customized note");
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
            [self showAlertToSearch];
            break;
        }
        case kSampleFunctionsViewMyNotes:
        {
            NotebooksViewController * notebooksVC = [[NotebooksViewController alloc] init];
            [self.navigationController pushViewController:notebooksVC animated:YES];
            break;
        }
        case kSampleFunctionsCustomizeNote:
        {
            [self saveCustomizedNote];
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
    __weak typeof(self) weakSelf = self;
    UIAlertAction *clipAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *urlField = clipController.textFields[0];
        NSString *urlString = urlField.text;
        [weakSelf loadWebViewWithURLString:urlString];
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [clipController addAction:clipAction];
    [clipController addAction:dismissAction];
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:clipController animated:YES completion:nil];
}

- (void)loadWebViewWithURLString:(NSString *)urlString {
    NSURL *urlToClip = [NSURL URLWithString:urlString];
    if (urlToClip == nil) {
        [CommonUtils showSimpleAlertWithMessage:@"URL not valid"];
        return;
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.window.bounds];
    self.webView.navigationDelegate = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [self.webView loadRequest:[NSURLRequest requestWithURL:urlToClip]];
}

- (void)clipWebPage {
    WKWebView * webView = self.webView;
    self.webView.navigationDelegate = nil;
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

#pragma mark - Search via keyword

- (void)showAlertToSearch {
    UIAlertController *searchController = [UIAlertController alertControllerWithTitle:@"Please enter the keyword:" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [searchController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = @"Evernote Business";
    }];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *clipAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *keywordField = searchController.textFields[0];
        NSString *keyword = keywordField.text;
        NoteListResultViewController *resultVC = [[NoteListResultViewController alloc] initWithNoteSearch:[ENNoteSearch noteSearchWithSearchString: keyword] notebook:nil];
        [weakSelf.navigationController pushViewController:resultVC animated:YES];
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [searchController addAction:clipAction];
    [searchController addAction:dismissAction];
    [self presentViewController:searchController animated:YES completion:nil];
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

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    NSLog(@"Web view fail: %@", error);
    self.webView = nil;
    [self finishClip];
    [CommonUtils showSimpleAlertWithMessage:@"Failed to load web page to clip."];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
{
    // At the end of every load complete, cancel a pending perform and start a new one. We wait for 3
    // seconds for the page to "settle down"
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    [self performSelector:@selector(clipWebPage) withObject:nil afterDelay:3.0];
}

#pragma mark - Customize a note

- (void)saveCustomizedNote {
    ENNote *noteToSave = [[ENNote alloc] init];
    noteToSave.title = @"Customized Note";
    NSString *content1 = @"Today I'm writing about my favorite apps on my iPhone\n";
    NSString *content2 = @"The first one is Evernote";
    UIImage *content3 = [UIImage imageNamed:@"evernote1"];
    NSString *content4 = @"I use it all the time on my phone";
    UIImage *content5 = [UIImage imageNamed:@"evernote2"];
    NSString *content6 = @"I can even read WSJ with it";
    UIImage *content7 = [UIImage imageNamed:@"evernote3"];
    NSString *content8 = @"\nThe second one is Penulimate";
    UIImage *content9 = [UIImage imageNamed:@"penultimate1"];
    NSString *content10 = @"I can draw stuff in Penultimate and sync with Evernote";
    UIImage *content11 = [UIImage imageNamed:@"penultimate2"];
    NSString *content12 = @"\nThe third app is Skitch";
    UIImage *content13 = [UIImage imageNamed:@"skitch1"];
    NSString *content14 = @"I can quickly markup something and send to my friends, or co workers. \nIt's so awesome";
    UIImage *content15 = [UIImage imageNamed:@"skitch2"];
    NSString *content16 = @"Surprisingly all of those apps are from Evernote!\n";
    NSString *content17 = @"Go download them all from http://www.evernote.com";
    ENNoteContent *noteContent = [ENNoteContent noteContentWithContentArray:@[content1, content2, content3, content4, content5, content6, content7, content8, content9, content10,
                                                                              content11, content12, content13, content14, content15, content16, content17]];
    [noteToSave setContent:noteContent];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [[ENSession sharedSession] uploadNote:noteToSave notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
        NSString * message = nil;
        if (noteRef) {
            message = @"Customized note saved.";
        } else {
            message = @"Failed to save customized note.";
        }
        [SVProgressHUD dismiss];
        [CommonUtils showSimpleAlertWithMessage:message];
    }];
}

@end
