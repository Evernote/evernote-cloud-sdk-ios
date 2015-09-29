//
//  SaveActivityViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "SaveActivityViewController.h"
#import <ENSDK/ENSDK.h>
#import "ENSaveToEvernoteViewController.h"
#import "CommonUtils.h"

@interface SaveActivityViewController () <ENSaveToEvernoteActivityDelegate, ENSendToEvernoteViewControllerDelegate>

@end

@implementation SaveActivityViewController

- (void)loadView {
    [super loadView];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.textView setText:@"This text will become the body of the note."];
    [self.view addSubview:self.textView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setTitle:NSLocalizedString(@"Save Activity", @"Save Activity")];
//    UIBarButtonItem * actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
    UIBarButtonItem * actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveToEvernote)];
    [self.navigationItem setRightBarButtonItem:actionItem];
}

- (void)action:(id)sender
{
//    You can customize the Evernote login prompts
    [ENSession sharedSession].customEvernoteLoginTitle = @"Custom Login Prompt";
    [ENSession sharedSession].customEvernoteLoginDescription = @"Please login to Evernote service in order to proceed";
    ENSaveToEvernoteActivity * sendActivity = [[ENSaveToEvernoteActivity alloc] init];
    sendActivity.delegate = self;
    UIImage *logoImage = [UIImage imageNamed:@"scannable"];
    NSURL *appURL = [NSURL URLWithString:@"https://evernote.com/products/scannable/"];
    NSString *stringToAppend = [NSString stringWithFormat:@"%@\n", self.textView.text];
    NSArray * items = @[stringToAppend, logoImage, appURL];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                      applicationActivities:@[sendActivity]];
    if ([activityController respondsToSelector:@selector(popoverPresentationController)]) {
        activityController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)saveToEvernote {
    ENSaveToEvernoteViewController *vc = [[ENSaveToEvernoteViewController alloc] init];
    vc.delegate = self;
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma ENSaveToEvernoteActivityDelegate
- (void)activity:(ENSaveToEvernoteActivity *)activity didFinishWithSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Saved to Evernote!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    } else {
        NSLog(@"Activity Error: %@", error);
    }
}

#pragma ENSaveToEvernoteViewController

- (ENNote *)noteForViewController:(ENSaveToEvernoteViewController *)viewController {
    ENNote *noteToSave = [[ENNote alloc] init];
    noteToSave.content = [ENNoteContent noteContentWithString:self.textView.text];
    return noteToSave;
}

- (NSString *)defaultNoteTitleForViewController:(ENSaveToEvernoteViewController *)viewController {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSDate *date = [NSDate date];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];

    return [NSString stringWithFormat:@"Written on %@", formattedDateString];
}

- (void)viewController:(ENSaveToEvernoteViewController *)viewController didFinishWithSuccess:(BOOL)success uploadError:(NSError *)error {
    if (success) {
        [CommonUtils showSimpleAlertWithMessage:@"Note saved successfully!"];
    } else {
        [CommonUtils showSimpleAlertWithMessage:@"Note failed to save!"];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
