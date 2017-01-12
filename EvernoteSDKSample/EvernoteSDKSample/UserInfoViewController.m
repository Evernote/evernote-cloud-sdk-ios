//
//  UserInfoViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "UserInfoViewController.h"
#import <EvernoteSDK/EvernoteSDK.h>

@interface UserInfoViewController ()

@end

@implementation UserInfoViewController

- (void)loadView {
    [super loadView];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setTitle:NSLocalizedString(@"User info", @"User info")];
    ENSession *sesssion = [ENSession sharedSession];
    NSMutableString * str = [NSMutableString string];
    [str appendFormat:@"Display name: %@\n", [[ENSession sharedSession] userDisplayName]];
    if ([sesssion isPremiumUser]) {
        [str appendString:@"User is a Premium user\n"];
    } else {
        [str appendString:@"User is not a Premium user.\n"];
    }
    
    [str appendFormat:@"\nUser's personal usage: %lld / %lld, percentage %.2f %%\n", [sesssion personalUploadUsage], [sesssion personalUploadLimit], [sesssion personalUploadUsage] * 100.0 / [sesssion personalUploadLimit]];

    if ([sesssion isBusinessUser]) {
        [str appendFormat:@"\nMember of the business \"%@\"\n", [sesssion businessDisplayName]];
        
        [str appendFormat:@"User's business usage: %lld / %lld, percentage %.2f %%\n", [sesssion businessUploadUsage], [sesssion businessUploadLimit], [sesssion businessUploadUsage] * 100.0 / [sesssion businessUploadLimit]];

    } else {
        [str appendString:@"User is not a Business user.\n"];
    }
    
    [self.textView setText:str];
}
@end
