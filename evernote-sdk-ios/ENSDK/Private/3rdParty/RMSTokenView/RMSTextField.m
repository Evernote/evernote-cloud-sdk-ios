//
//  RMSTextField.m
//  RMSTokenView
//
//  Created by Patrick Strawderman on 5/5/14.
//  Copyright (c) 2014 RoleModel Software. All rights reserved.
//

#import "RMSTextField.h"

@implementation RMSTextField

- (void)deleteBackward {
    if ([self.backspaceDelegate respondsToSelector:@selector(willDeleteBackward:)]) {
        [self.backspaceDelegate willDeleteBackward:self];
    }
    [super deleteBackward];
    if ([self.backspaceDelegate respondsToSelector:@selector(didDeleteBackward:)]) {
        [self.backspaceDelegate didDeleteBackward:self];
    }
}

@end
