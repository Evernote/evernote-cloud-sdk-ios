//
//  SaveActivityViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "SaveActivityViewController.h"
#import <ENSDK/ENSDK.h>

@interface SaveActivityViewController () <ENSaveToEvernoteActivityDelegate>

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
    [self.navigationItem setTitle:@"Save Activity"];
    UIBarButtonItem * actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
    [self.navigationItem setRightBarButtonItem:actionItem];
}

- (void)action:(id)sender
{
    ENSaveToEvernoteActivity * sendActivity = [[ENSaveToEvernoteActivity alloc] init];
    sendActivity.delegate = self;
    NSArray * items = [NSArray arrayWithObject:(self.textView.text)];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                      applicationActivities:@[sendActivity]];
    [self presentViewController:activityController animated:YES completion:nil];
}

#pragma ENSaveToEvernoteActivityDelegate
- (void)activity:(ENSaveToEvernoteActivity *)activity didFinishWithSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Saved to Evernote!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Fail" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

@end
