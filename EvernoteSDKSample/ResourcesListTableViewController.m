//
//  ResourcesTableTableViewController.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 1/2/15.
//  Copyright (c) 2015 Evernote Corporation. All rights reserved.
//

#import "ResourcesListTableViewController.h"
#import "CommonUtils.h"

@interface ResourcesListTableViewController ()

@property (nonatomic, strong) ENNote *note;
@property (nonatomic, strong) ENNoteRef *noteRef;
@property (nonatomic, strong) NSArray *resourceList;

@end

@implementation ResourcesListTableViewController

- (id)initWithNote:(ENNote *)note noteRef:(ENNoteRef *)noteRef{
    if (self = [super init]) {
        self.note = note;
        self.noteRef = noteRef;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationItem setTitle:@"Resources"];
    
    self.resourceList = self.note.resources;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.resourceList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notebook"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"notebook"];
    }
    
    ENResource *resource = [self.resourceList objectAtIndex:indexPath.row];
    if ([resource.filename length]) {
        [cell.textLabel setText:resource.filename];
    } else {
        [cell.textLabel setText:[NSString stringWithFormat:@"Resource: %@", resource.mimeType]];
    }
    
    if (resource.data && [resource.mimeType hasPrefix:@"image"]) {
        [cell.imageView setImage:[UIImage imageWithData:resource.data]];
    }
    
    return cell;
}

@end
