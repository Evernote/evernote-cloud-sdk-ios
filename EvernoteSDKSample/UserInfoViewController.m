//
//  UserInfoViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "UserInfoViewController.h"
#import <ENSDK/ENSDK.h>

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
    [self.navigationItem setTitle:@"User Info"];
    NSMutableString * str = [NSMutableString string];
    [str appendFormat:@"Display name: %@\n", [[ENSession sharedSession] userDisplayName]];
    if ([[ENSession sharedSession] isBusinessUser]) {
        [str appendFormat:@"Member of the business \"%@\"\n", [[ENSession sharedSession] businessDisplayName]];
    } else {
        [str appendString:@"User is not a Business user.\n"];
    }
    if ([[ENSession sharedSession] isPremiumUser]) {
        [str appendString:@"User is a Premium user\n"];
    } else {
        [str appendString:@"User is not a Premium user.\n"];
    }
    
    [self.textView setText:str];
}
@end
