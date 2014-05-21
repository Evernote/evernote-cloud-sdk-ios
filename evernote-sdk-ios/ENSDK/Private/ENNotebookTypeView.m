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

#import "ENNotebookTypeView.h"
#import "ENTheme.h"

static CGFloat const kCircleRadius = 13;

@implementation ENNotebookTypeView {
    UIImageView *_imageView;
    UIColor *_circleColor;
    UIColor *_circleBorderColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeCenter;
        self.backgroundColor = [UIColor clearColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)setIsBusiness:(BOOL)isBusiness {
    _isBusiness = isBusiness;
    UIImage* notebookTypeIcon = isBusiness? [UIImage imageNamed:@"ENSDKResources.bundle/ENBusinessIcon"] : [UIImage imageNamed:@"ENSDKResources.bundle/ENMultiplePeopleIcon"];
    _imageView.image = [notebookTypeIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_imageView sizeToFit];
    [self updateNotebookTypeIconColor];
    [self setNeedsLayout];
    [self setNeedsDisplay];

}

- (void)layoutSubviews{
    [super layoutSubviews];
    _imageView.center = CGPointMake(floorf(CGRectGetMidX(self.bounds)), floorf(CGRectGetMidY(self.bounds)));
}

- (void)drawRect:(CGRect)rect
{
    CGPoint imageCenter = _imageView.center;
    CGFloat radius = kCircleRadius;
    
    CGPoint circleOrigin = CGPointMake(imageCenter.x - radius, imageCenter.y - radius);
    UIBezierPath* path = [UIBezierPath bezierPathWithOvalInRect:CGRectIntegral(CGRectMake(circleOrigin.x, circleOrigin.y, radius*2, radius*2))];
    
    UIColor* circleColor = _circleColor;
    UIColor* circleBorderColor = _circleBorderColor;
    
    if([self tintAdjustmentMode] == UIViewTintAdjustmentModeDimmed){
        circleBorderColor = [self tintColor];
        circleColor = [circleColor colorWithAlphaComponent:0.6];
    }
    
    [circleBorderColor setStroke];
    [path setLineWidth:1];
    [path stroke];
    
    if(circleColor != nil){
        [circleColor setFill];
        [path fill];
    }
}

- (void)updateNotebookTypeIconColor {
    _imageView.tintColor = _isBusiness? [ENTheme defaultBusinessColor] : [ENTheme defaultShareColor];
}

- (void)didMoveToWindow{
    [super didMoveToWindow];
    [self updateThemeColors];
}

- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    [self updateThemeColors];
}

- (void)updateThemeColors{
    _circleBorderColor = [[ENTheme defaultShareColor] colorWithAlphaComponent:0.08];
    _circleColor = [_circleBorderColor colorWithAlphaComponent:0.03];
}

@end
