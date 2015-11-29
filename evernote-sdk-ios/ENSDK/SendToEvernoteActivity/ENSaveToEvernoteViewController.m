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

#import "ENSaveToEvernoteViewController.h"
#import "ENNotebookChooserViewController.h"
#import "ENNotebookPickerButton.h"
#import "ENSDK.h"
#import "ENTheme.h"
#import "RMSTokenView.h"
#import "ENNotebookPickerView.h"
#import "ENSDKPrivate.h"
#import "ENSaveToEvernoteActivity.h"

#define kTitleViewHeight        50.0
#define kTagsViewHeight         44.0
#define kNotebookViewHeight     50.0

CGFloat kTextLeftPadding = 20;

@interface ENSaveToEvernoteActivity (Private)
- (ENNote *)preparedNote;
@end

@interface ENSaveToEvernoteViewController () <ENNotebookChooserViewControllerDelegate>
@property (nonatomic, strong) UIBarButtonItem * saveButtonItem;
@property (nonatomic, strong) UITextField * titleField;
@property (nonatomic, strong) UITextField * notebookField;
@property (nonatomic, strong) ENNotebookPickerView *notebookPickerView;
@property (nonatomic, strong) ENNotebookPickerButton * notebookPickerButton;
@property (nonatomic, strong) RMSTokenView * tagsView;
@property (nonatomic, strong) UIWebView * noteView;

@property (nonatomic, strong) NSArray * notebookList;
@property (nonatomic, strong) ENNotebook * currentNotebook;
@end

@implementation ENSaveToEvernoteViewController

- (void)loadView {
    [super loadView];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    [self.view setBackgroundColor:[ENTheme defaultBackgroundColor]];
    [self.navigationController.view setTintColor:[ENTheme defaultTintColor]];
    
    UITextField *titleField = [[UITextField alloc] initWithFrame:CGRectZero];
    titleField.translatesAutoresizingMaskIntoConstraints = NO;
    [titleField setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    [titleField setTextColor:[UIColor colorWithRed:0.51 green:0.51 blue:0.51 alpha:1]];
    UIView *paddingView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kTextLeftPadding, 0)];
    titleField.leftView = paddingView1;
    titleField.leftViewMode = UITextFieldViewModeAlways;
    titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:titleField];
    self.titleField = titleField;
    
    UIView *divider1 = [[UIView alloc] initWithFrame:CGRectZero];
    divider1.translatesAutoresizingMaskIntoConstraints = NO;
    [divider1 setBackgroundColor: [ENTheme defaultSeparatorColor]];
    [self.view addSubview:divider1];
    
    RMSTokenView *tagsView = [[RMSTokenView alloc] initWithFrame:CGRectZero];
    tagsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tagsView];
    self.tagsView = tagsView;
    
    ENNotebookPickerView *notebookView = [[ENNotebookPickerView alloc] initWithFrame:CGRectZero];
    notebookView.translatesAutoresizingMaskIntoConstraints = NO;
    [notebookView addTarget:self action:@selector(showNotebookChooser) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:notebookView];
    self.notebookPickerView = notebookView;
    self.notebookPickerButton = notebookView.notebookPickerButton;
    [self.notebookPickerButton addTarget:self action:@selector(showNotebookChooser) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *divider3 = [[UIView alloc] initWithFrame:CGRectZero];
    divider3.translatesAutoresizingMaskIntoConstraints = NO;
    [divider3 setBackgroundColor:[ENTheme defaultSeparatorColor]];
    [self.view addSubview:divider3];
    
    UIWebView *noteView = [[UIWebView alloc] initWithFrame:CGRectZero];
    noteView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:noteView];
    self.noteView = noteView;
    
    NSString *format = [NSString stringWithFormat:@"V:|[titleField(%f)][divider1(%f)][tagsView(>=%f)][notebookView(%f)][divider3(%f)][noteView]|", kTitleViewHeight, OnePxHeight(), kTagsViewHeight, kNotebookViewHeight, OnePxHeight()];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:format
                                                                       options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(titleField, divider1, tagsView, notebookView, divider3, noteView)]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleField]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(titleField)]];
    
    self.navigationItem.title = ENSDKLocalizedString(@"Save to Evernote", @"Save to Evernote");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    self.saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = self.saveButtonItem;
    
    self.saveButtonItem.enabled = NO;
    self.titleField.text = [self.delegate defaultNoteTitleForViewController:self];
    [self.titleField setPlaceholder:ENSDKLocalizedString(@"Add Title", @"Add Title")];

    self.tagsView.placeholder = ENSDKLocalizedString(@"Add Tag", @"Add Tag");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Kick off the notebook list fetch.
    [[ENSession sharedSession] listWritableNotebooksWithCompletion:^(NSArray *notebooks, NSError *listNotebooksError) {
        self.notebookList = notebooks;
        // Populate the notebook picker with the default notebook.
        for (ENNotebook * notebook in notebooks) {
            if (notebook.isDefaultNotebook) {
                self.currentNotebook = notebook;
                [self updateCurrentNotebookDisplay];
                break;
            }
        }
        self.saveButtonItem.enabled = YES;
    }];
    
    ENNote * note = [self.delegate noteForViewController:self];
    for (NSString *tagName in note.tagNames) {
        [self.tagsView addTokenWithText:tagName];
    }
    [note generateWebArchiveData:^(NSData *data) {
        [self.noteView loadData:data
                      MIMEType:ENWebArchiveDataMIMEType
              textEncodingName:nil
                       baseURL:nil];
    }];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateCurrentNotebookDisplay
{
    NSString * displayName = self.currentNotebook.name;
    [self.notebookPickerButton setIsBusinessNotebook:(self.currentNotebook.isBusinessNotebook)];
    [self.notebookPickerButton setTitle:displayName forState:UIControlStateNormal];
    if ([self.notebookList count] == 1) {
        self.notebookPickerButton.shouldHideDisclosureIndicator = YES;
        [self.notebookPickerButton setEnabled:NO];
        [self.notebookPickerView setEnabled:NO];
    } else {
        self.notebookPickerButton.shouldHideDisclosureIndicator = NO;
        [self.notebookPickerButton setEnabled:YES];
        [self.notebookPickerView setEnabled:YES];
    }
}

- (void)showNotebookChooser
{
    ENNotebookChooserViewController * chooser = [[ENNotebookChooserViewController alloc] init];
    chooser.delegate = self;
    chooser.notebookList = self.notebookList;
    chooser.currentNotebook = self.currentNotebook;
    [self.navigationController pushViewController:chooser animated:YES];
}

#pragma mark - Actions

- (void)save:(id)sender
{
    // Fetch the note we've built so far.
    ENNote * note = [self.delegate noteForViewController:self];

    // Populate the metadata fields we offered.
    note.title = self.titleField.text;
    if (note.title.length == 0) {
        note.title = ENSDKLocalizedString(@"Untitled note", @"Untitled note");
    }
    
    NSArray * tags = [self.tagsView tokens];
    if (tags.count > 0) {
        note.tagNames = tags;
    }
    
    // Upload the note.
    [[ENSession sharedSession] uploadNote:note notebook:self.currentNotebook completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
        [self.delegate viewController:self didFinishWithSuccess:(noteRef != nil) uploadError:uploadNoteError];
    }];
}

- (void)cancel:(id)sender
{
    [self.delegate viewController:self didFinishWithSuccess:NO uploadError:[NSError errorWithDomain:ENErrorDomain code:ENErrorCodeCancelled userInfo:nil]];
}

#pragma mark - ENNotebookChooserViewControllerDelegate

- (void)notebookChooser:(ENNotebookChooserViewController *)chooser didChooseNotebook:(ENNotebook *)notebook
{
    self.currentNotebook = notebook;
    [self updateCurrentNotebookDisplay];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
