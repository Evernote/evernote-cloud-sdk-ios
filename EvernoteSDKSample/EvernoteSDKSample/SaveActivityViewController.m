//
//  SaveActivityViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "SaveActivityViewController.h"
#import <EvernoteSDK/EvernoteSDK.h>

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
    [self.navigationItem setTitle:NSLocalizedString(@"Save Activity", @"Save Activity")];
    UIBarButtonItem * actionItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
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

#pragma ENSaveToEvernoteActivityDelegate
- (void)activity:(ENSaveToEvernoteActivity *)activity didFinishWithSuccess:(BOOL)success error:(NSError *)error {
    if (success) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Saved to Evernote" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        NSLog(@"Activity Error: %@", error);
    }
}

@end
