//
//  ResourcesTableTableViewController.h
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 1/2/15.
//  Copyright (c) 2015 Evernote Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ENSDK/ENSDK.h>

@interface ResourcesTableTableViewController : UITableViewController

- (id)initWithNote:(ENNote *)noteRef;

@end
