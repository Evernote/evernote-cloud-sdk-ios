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

#import "ENNotebookPickerButton.h"
#import "ENTheme.h"

#define kTextImageSpace         10.0
#define kRightPadding           30.0
#define kDisclosureRightMargin  15.0

@interface ENNotebookPickerButton ()

@property (nonatomic, strong) UIImageView *discloureIndicator;

@end

@implementation ENNotebookPickerButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
        UIImage *dislosureImage = [[UIImage imageNamed:@"ENSDKResources.bundle/ENNextIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.discloureIndicator = [[UIImageView alloc] initWithImage:dislosureImage];
        [self.discloureIndicator setTintColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1]];
        
        self.discloureIndicator.center = CGPointMake(CGRectGetMaxX(self.bounds) - kDisclosureRightMargin, CGRectGetMidY(self.bounds));
        [self.discloureIndicator setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
        [self addSubview:self.discloureIndicator];
        
        [self.imageView setTintColor:[ENTheme defaultTintColor]];
    }
    return self;
}

- (void)setIsBusinessNotebook:(BOOL)isBusinessNotebook {
    if (_isBusinessNotebook == isBusinessNotebook) return;
    _isBusinessNotebook = isBusinessNotebook;
    if (_isBusinessNotebook) {
        [self setImage:[[UIImage imageNamed:@"ENSDKResources.bundle/ENBusinessIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [self setImage:nil forState:UIControlStateNormal];
    }
}

- (void)setShouldHideDisclosureIndicator:(BOOL)shouldHideDisclosureIndicator {
    _shouldHideDisclosureIndicator = shouldHideDisclosureIndicator;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.discloureIndicator setHidden:_shouldHideDisclosureIndicator];
    if (_shouldHideDisclosureIndicator) {
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, kDisclosureRightMargin)];
        [self setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, kDisclosureRightMargin)];
    } else {
        [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 2 * kDisclosureRightMargin)];
        [self setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 2 * kDisclosureRightMargin)];
    }
}

@end
