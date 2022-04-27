//
//  NotebooksViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "NotebooksViewController.h"
#import <EvernoteSDK/EvernoteSDK.h>
#import "CommonUtils.h"
#import "NoteListResultViewController.h"
#import "SVProgressHUD.h"

@interface NotebooksViewController ()

@property (nonatomic, strong) NSArray *notebookList;
@property (nonatomic, strong) UIBarButtonItem *createNewNotebookItem;
@property (nonatomic) BOOL creatingBusinessNotebook;

@end

@implementation NotebooksViewController

- (void)loadView {
    [super loadView];
    
    self.createNewNotebookItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewNotebook)];
    self.navigationItem.rightBarButtonItem = self.createNewNotebookItem;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationItem setTitle:@"My Notebooks"];
    
    [self reloadNotebooks];
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

- (void)createNewNotebook {
    if ([[ENSession sharedSession] isBusinessUser]) {
        UIAlertController *notebookTypeAlertController = [UIAlertController alertControllerWithTitle:@"Please choose the notebook type" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        __weak typeof(self) weakSelf = self;
        UIAlertAction *personalAction = [UIAlertAction actionWithTitle:@"Personal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf showAlertToEnterNotebookName];
        }];
        UIAlertAction *businessAction = [UIAlertAction actionWithTitle:@"Business" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            weakSelf.creatingBusinessNotebook = YES;
            [weakSelf showAlertToEnterNotebookName];
        }];
        [notebookTypeAlertController addAction:personalAction];
        [notebookTypeAlertController addAction:businessAction];
        [self presentViewController:notebookTypeAlertController animated:YES completion:nil];
    } else {
        [self showAlertToEnterNotebookName];
    }
}

- (void)showAlertToEnterNotebookName {
    UIAlertController *notebookNameAlertController = [UIAlertController alertControllerWithTitle:@"Please enter the notebook name" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [notebookNameAlertController addTextFieldWithConfigurationHandler:nil];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *notebookNameField = notebookNameAlertController.textFields[0];
        NSString *notebookName = notebookNameField.text;
        if ([notebookName length] < 1) {
            [CommonUtils showSimpleAlertWithMessage:@"Notebook name invalid!"];
            return;
        }
        
        EDAMNotebook *notebookToCreate = [[EDAMNotebook alloc] init];
        notebookToCreate.name = notebookName;

        if (weakSelf.creatingBusinessNotebook) {
            [[ENSession sharedSession].businessNoteStore createBusinessNotebook:notebookToCreate completion:^(EDAMLinkedNotebook *notebook,NSError *error) {
                if(notebook){
                NSLog(@"Successfully created business notebook %@", notebook);
                [weakSelf reloadNotebooks];
            } else {
                NSLog(@"Failed to create the notebook with error %@", error);
            }}];
            weakSelf.creatingBusinessNotebook = NO;
        } else {
[[ENSession sharedSession].primaryNoteStore createNotebook:notebookToCreate completion:^(EDAMNotebook *notebook,NSError *error) {
                if(notebook){
                NSLog(@"Successfully created personal notebook %@", notebook);
                [weakSelf reloadNotebooks];
            } else{
                NSLog(@"Failed to create the notebook with error %@", error);
            }}];
        }
    }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [notebookNameAlertController addAction:createAction];
    [notebookNameAlertController addAction:dismissAction];
    [self presentViewController:notebookNameAlertController animated:YES completion:nil];
}

- (void)reloadNotebooks {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    __weak typeof(self) weakSelf = self;
    [[ENSession sharedSession] listNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        [SVProgressHUD dismiss];
        if (listNotebooksError) {
            [CommonUtils showSimpleAlertWithMessage:[listNotebooksError localizedDescription]];
            return;
        }
        
        weakSelf.notebookList = notebooks;
        [weakSelf.tableView reloadData];
    }];
}

@end
