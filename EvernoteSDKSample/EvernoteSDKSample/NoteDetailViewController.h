//
//  ViewNoteViewController.h
//  evernote-sdk-ios
//
//  Created by Ben Zotto on 5/22/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EvernoteSDK/EvernoteSDK.h>

@interface NoteDetailViewController : UIViewController
@property (nonatomic, strong) ENNoteRef * noteRef;
@property (nonatomic, strong) NSString * noteTitle;
@end
