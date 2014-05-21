//
//  SaveActivityViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "SaveActivityViewController.h"
#import <ENSDK/ENSDK.h>

@interface SaveActivityViewController ()

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
    NSArray * items = [NSArray arrayWithObject:(self.textView.text)];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                                      applicationActivities:@[sendActivity]];
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
