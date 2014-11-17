//
//  SearchNotesViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "SearchNotesViewController.h"
#import <ENSDK/ENSDK.h>
#import "SearchNotesResultViewController.h"

@interface SearchNotesViewController ()

@end

@implementation SearchNotesViewController

- (void)loadView {
    [super loadView];
    self.backgroundView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.backgroundView];
    
    CGRect frame = self.backgroundView.bounds;
    CGRect labelFrame, keywordFrame;
    CGRectDivide(frame, &labelFrame, &frame, 44.0, CGRectMinYEdge);
    CGRectDivide(frame, &keywordFrame, &frame, 44.0, CGRectMinYEdge);
    
    self.instructionLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [self.instructionLabel setText:@"Please specify the keyword to search"];
    [self.instructionLabel setTextAlignment:NSTextAlignmentCenter];
    [self.backgroundView addSubview:self.instructionLabel];
    
    self.keywordField = [[UITextField alloc] initWithFrame:keywordFrame];
    [self.keywordField setPlaceholder:@"Evernote Business"];
    [self.keywordField setTextAlignment:NSTextAlignmentCenter];
    [self.backgroundView addSubview:self.keywordField];
    
    [self.navigationItem setTitle:@"Search Notes"];
    UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchNotes)];
    self.navigationItem.rightBarButtonItem = searchItem;
}

- (void)searchNotes {
    SearchNotesResultViewController *resultVC = [[SearchNotesResultViewController alloc] initWithKeyword:self.keywordField.text];
    [self.navigationController pushViewController:resultVC animated:YES];
}

@end
