//
//  ENNotebookPickerView.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 5/19/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "ENNotebookPickerView.h"
#import "ENTheme.h"
#import "ENSDKPrivate.h"

extern CGFloat kTextLeftPadding;
CGFloat kLabelButtonSpace = 10.0;

@implementation ENNotebookPickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UILabel *notebookLabel = [[UILabel alloc] init];
        [notebookLabel setText:ENSDKLocalizedString(@"Notebook", @"Notebook")];
        [notebookLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0]];
        [self addSubview:notebookLabel];
        self.notebookLabel = notebookLabel;
        
        ENNotebookPickerButton *notebookPickerButton = [[ENNotebookPickerButton alloc] init];
        [notebookPickerButton setTitleColor:[ENTheme defaultTintColor] forState:UIControlStateNormal];
        [notebookPickerButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0]];
        [self addSubview:notebookPickerButton];
        self.notebookPickerButton = notebookPickerButton;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.bounds;
    frame.origin.x = kTextLeftPadding;
    frame.size.width -= frame.origin.x;
    CGFloat labelWidth = [_notebookLabel sizeThatFits:CGSizeZero].width;
    CGRect frame1, frame2;
    CGRectDivide(frame, &frame1, &frame2, labelWidth, CGRectMinXEdge);
    [_notebookLabel setFrame:frame1];
    CGRect frame3, frame4;
    CGRectDivide(frame2, &frame3, &frame4, kLabelButtonSpace, CGRectMinXEdge);
    [_notebookPickerButton setFrame:frame4];
}

@end
