//
//  ViewAppNotesViewController.m
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 5/22/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "SearchNotesResultViewController.h"
#import <ENSDK/ENSDK.h>
#import "ViewNoteViewController.h"
#import "SVProgressHUD.h"

@interface SearchNotesResultViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSArray * findNotesResults;
@property (nonatomic, strong) NSMutableDictionary * thumbnails;
@end

@implementation SearchNotesResultViewController

- (instancetype)initWithKeyword:(NSString *)keyword {
    if (self = [super init]) {
        self.keyword = keyword;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
    
    self.thumbnails = [[NSMutableDictionary alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Notes";
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[ENSession sharedSession] findNotesWithSearch:[ENNoteSearch noteSearchWithSearchString:self.keyword]
                                        inNotebook:nil
                                           orScope:ENSessionSearchScopeAll
                                         sortOrder:ENSessionSortOrderRecentlyCreated
                                        maxResults:0
                                        completion:^(NSArray *findNotesResults, NSError *findNotesError) {
                                            [SVProgressHUD dismiss];
                                            if (!findNotesResults) {
                                                if ([findNotesError.domain isEqualToString:ENErrorDomain] &&
                                                    findNotesError.code == ENErrorCodePermissionDenied) {
                                                    [self showSimpleAlertWithMessage:@"Permission denied for note find. Maybe your app only has read access?"];
                                                } else {
                                                    [self showSimpleAlertWithMessage:@"Error searching for notes"];
                                                }
                                                NSLog(@"findNotesError: %@", findNotesError);
                                            } else if (findNotesResults.count == 0) {
                                                [self showSimpleAlertWithMessage:@"No notes from this app! Go back to menu to create some."];
                                            } else {
                                                self.findNotesResults = findNotesResults;
                                                [self.tableView reloadData];
                                            }
                                        }];
}

- (void)showSimpleAlertWithMessage:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.findNotesResults) {
        return self.findNotesResults.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    ENSessionFindNotesResult * result = self.findNotesResults[indexPath.row];
    cell.textLabel.text = result.title;
    UIImage * knownThumbnail = self.thumbnails[result.noteRef];
    if (knownThumbnail) {
        cell.imageView.image = knownThumbnail;
    } else {
        [[ENSession sharedSession] downloadThumbnailForNote:result.noteRef
                                               maxDimension:100
                                                 completion:^(UIImage *thumbnail, NSError *downloadNoteThumbnailError) {
                                                     if (thumbnail) {
                                                         self.thumbnails[result.noteRef] = thumbnail;
                                                         [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                     }
                                                 }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ENSessionFindNotesResult * result = self.findNotesResults[indexPath.row];
    ViewNoteViewController * vc = [[ViewNoteViewController alloc] init];
    vc.noteRef = result.noteRef;
    vc.noteTitle = result.title;
    [self.navigationController pushViewController:vc animated:YES];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
