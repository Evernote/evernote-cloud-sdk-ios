//
//  NotebooksViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "NotebooksViewController.h"
#import <ENSDK/ENSDK.h>
#import "CommonUtils.h"
#import "NoteListResultViewController.h"

@interface NotebooksViewController ()

@property (nonatomic, strong) NSArray *notebookList;

@end

@implementation NotebooksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationItem setTitle:@"My Notebooks"];
    
    [[ENSession sharedSession] listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        if (listNotebooksError) {
            [CommonUtils showSimpleAlertWithMessage:[listNotebooksError localizedDescription]];
            return;
        }
        
        self.notebookList = notebooks;
        [self.tableView reloadData];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notebookList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notebook"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"notebook"];
    }
    
    ENNotebook *notebook = [self.notebookList objectAtIndex:indexPath.row];
    NSString *nameToDisplay = notebook.name;
    if (notebook.isBusinessNotebook) {
        nameToDisplay = [NSString stringWithFormat:@"🏢 %@", nameToDisplay];
    } else if (notebook.isShared) {
        nameToDisplay = [NSString stringWithFormat:@"👥 %@", nameToDisplay];
    } else {
        nameToDisplay = [NSString stringWithFormat:@"👤 %@", nameToDisplay];
    }
    [cell.textLabel setText:nameToDisplay];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ENNotebook *notebook = [self.notebookList objectAtIndex:indexPath.row];
    NoteListResultViewController *resultVC = [[NoteListResultViewController alloc] initWithNoteSearch:nil notebook:notebook];
    [self.navigationController pushViewController:resultVC animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
