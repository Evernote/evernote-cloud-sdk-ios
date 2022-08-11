//
//  TagsInfoViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 10/10/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "TagsInfoViewController.h"
#import <EvernoteSDK/EvernoteSDK.h>

@interface TagsInfoViewController ()

@end

@implementation TagsInfoViewController

- (void)loadView {
    [super loadView];
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.textView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setTitle:NSLocalizedString(@"Tags", @"Tags")];
    NSMutableString * str = [NSMutableString string];
    
    [self.textView setText:str];

    [[ENSession sharedSession].primaryNoteStore listTagsWithCompletion:^(NSArray *tags,NSError *error) {
        if(tags){
        [str appendString:@"Personal Tags:\n"];
        for (EDAMTag *tag in tags) {
            [str appendFormat:@"%@\n", tag.name];
        }
        [str appendString:@"\n"];
        [self.textView setText:str];
    } else {
        NSLog(@"Error in fetching personal tags %@", error);
    }}];
    
    if ([[ENSession sharedSession] isBusinessUser]) {
        [[ENSession sharedSession].businessNoteStore listTagsWithCompletion:^(NSArray *tags,NSError *error) {
            if(tags){
            [str appendString:@"Business Tags:\n"];
            for (EDAMTag *tag in tags) {
                [str appendFormat:@"%@\n", tag.name];
            }
            [str appendString:@"\n"];
            [self.textView setText:str];
        } else {
            NSLog(@"Error in fetching business tags %@", error);
        }}];
    }
}

@end
