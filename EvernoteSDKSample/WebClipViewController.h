//
//  WebClipViewController.h
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebClipViewController : UIViewController
@property (nonatomic, strong) UIScrollView * backgroundView;
@property (nonatomic, strong) UILabel *instructionLabel;
@property (nonatomic, strong) UITextField *urlField;
@end
