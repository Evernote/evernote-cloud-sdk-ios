/*
 * Copyright (c) 2014 by Evernote Corporation, All rights reserved.
 *
 * Use of the source code and binary libraries included in this package
 * is permitted under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ENNotebookChooserViewController.h"
#import "ENNotebookCell.h"
#import "ENTheme.h"
#import "ENSDKAdvanced.h"

#define kENRecentNotebooksKey       @"ENRecentNotebooksKey"
#define kENRecentNotebooksCount     3

@interface ENNotebookChooserViewController () {
    struct {
        int8_t currentNotebookSection;
        int8_t recentNotebooksSection;
        int8_t notebooksSection;
        int8_t lastSection;
    } _sections;
}

@end

@implementation ENNotebookChooserViewController

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad
{
    self.title = ENSDKLocalizedString(@"Notebooks", @"Notebooks");
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reloadRecentNotebooks];
    [self rebuildSections];
    [super viewWillAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.lastSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _sections.currentNotebookSection) {
        return 1;
    } else if (section == _sections.recentNotebooksSection) {
        return [self.recentNotebookList count];
    } else {
        return [self.notebookList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ENNotebookCell * cell = [tableView dequeueReusableCellWithIdentifier:@"notebook"];
    if (!cell) {
        cell = [[ENNotebookCell alloc] initWithReuseIdentifier:@"notebook"];
        cell.backgroundColor = [UIColor whiteColor];
        if (IsIPad()) {
            cell.backgroundColor = [UIColor colorWithWhite:1. alpha:.05];
        }
    }
    
    ENNotebook * notebook;
    if (indexPath.section == _sections.currentNotebookSection) {
        notebook = self.currentNotebook;
    } else if (indexPath.section == _sections.notebooksSection) {
        notebook = self.notebookList[indexPath.row];
    } else if (indexPath.section == _sections.recentNotebooksSection) {
        notebook = self.recentNotebookList[indexPath.row];
    }
    [cell setNotebook:notebook];
    [cell setIsCurrentNotebook:[notebook isEqual:self.currentNotebook]];
    [cell setIsReadOnlyNotebook:![notebook allowsWriting]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ENNotebook * notebook;
    if (indexPath.section == _sections.currentNotebookSection) {
        notebook = self.currentNotebook;
    } else if (indexPath.section == _sections.recentNotebooksSection) {
        notebook = self.recentNotebookList[indexPath.row];
    } else {
        notebook = self.notebookList[indexPath.row];
    }
    [self saveRecentNotebook:notebook];
    [self.delegate notebookChooser:self didChooseNotebook:notebook];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    CGFloat backgroundColorAlpha = 1.;
    if (IsIPad()) {
        backgroundColorAlpha = 0.05;
    }
    if (tableView == self.tableView &&
        (section == _sections.currentNotebookSection ||
         section == _sections.recentNotebooksSection)) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
            footer.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:backgroundColorAlpha];
            return footer;
        }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView &&
        (section == _sections.currentNotebookSection ||
         section == _sections.recentNotebooksSection)) {
            return 4.;
        }
    return 0.;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat backgroundColorAlpha = 1.;
    if (IsIPad()) {
        backgroundColorAlpha = 0.05;
    }
    if (tableView == self.tableView) {
        NSString *headerTitle = nil;
        if (section == _sections.currentNotebookSection) {
            headerTitle = [ENSDKLocalizedString(@"Current", @"Current") uppercaseString];
        }
        else if (section == _sections.recentNotebooksSection) {
            headerTitle = [ENSDKLocalizedString(@"Recent Notebooks", @"Recent Notebooks") uppercaseString];
        }
        else {
            headerTitle = [ENSDKLocalizedString(@"All Notebooks", @"All Notebooks") uppercaseString];
        }
        return [self headerViewWithTitle:headerTitle
                         backgroundColor:[UIColor colorWithWhite:1. alpha:backgroundColorAlpha]
                               textColor:[UIColor colorWithRed:0.56f green:0.56f blue:0.56f alpha:1.00f]
                                    size:CGSizeMake(CGRectGetWidth(tableView.frame), 40)];
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (tableView == self.tableView && section == _sections.currentNotebookSection) {
        return 32.;
    }
    return 50.;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}

- (UIView *) headerViewWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor size:(CGSize)size {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    container.backgroundColor = backgroundColor;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.font = [UIFont fontWithName:@"Helvetica" size:11.];
    label.textColor = textColor;
    label.text = title;
    [label sizeToFit];
    CGRect frame = label.frame;
    frame.origin.x = 14.0;
    frame.origin.y = (CGRectGetHeight(container.bounds) - CGRectGetHeight(frame)) / 2.0;
    label.frame = frame;
    
    [container addSubview:label];
    return container;
}

- (void)rebuildSections {
    int sections = 0;
    if ([self showCurrentNotebook]) {
        _sections.currentNotebookSection = sections++;
    } else {
        _sections.currentNotebookSection = -1;
    }
    
    if ([self showRecentNotebook]) {
        _sections.recentNotebooksSection = sections++;
    } else {
        _sections.recentNotebooksSection = -1;
    }
    
    _sections.notebooksSection = sections++;
    _sections.lastSection = sections;
}

- (void)reloadRecentNotebooks {
    self.recentNotebookList = [[[ENSession sharedSession] preferences] decodedObjectForKey:kENRecentNotebooksKey];
}

- (void)saveRecentNotebook: (ENNotebook *)notebook {
    NSMutableArray *newRecentList = [NSMutableArray arrayWithObject:notebook];
    for (NSUInteger index = 0; index < self.recentNotebookList.count; index++) {
        ENNotebook *notebookToAdd = [self.recentNotebookList objectAtIndex:index];
        if ([notebookToAdd isEqual:notebook] == NO) [newRecentList addObject:notebookToAdd];
        if ([newRecentList count] == kENRecentNotebooksCount) break;
    }
    self.recentNotebookList = newRecentList;
    [[[ENSession sharedSession] preferences] encodeObject:self.recentNotebookList forKey:kENRecentNotebooksKey];
}

- (BOOL)showCurrentNotebook {
    return [self currentNotebook] != nil;
}

- (BOOL)showRecentNotebook {
    return [self.recentNotebookList count];
}

@end
