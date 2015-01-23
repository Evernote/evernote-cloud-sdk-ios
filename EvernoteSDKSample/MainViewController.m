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
#import "WebClipViewController.h"
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

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
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
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
            WebClipViewController * webClipVC = [[WebClipViewController alloc] init];
            [self.navigationController pushViewController:webClipVC animated:YES];
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
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
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
@end
