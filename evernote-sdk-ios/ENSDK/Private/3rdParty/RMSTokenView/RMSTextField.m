//
//  RMSTextField.m
//  RMSTokenView
//
//  Created by Patrick Strawderman on 5/5/14.
//  Copyright (c) 2014 RoleModel Software. All rights reserved.
//

#import "RMSTextField.h"

@implementation RMSTextField

// http://stackoverflow.com/questions/25354467/detect-backspace-in-uitextfield-in-ios8
- (BOOL)keyboardInputShouldDelete:(UITextField *)textField {
    BOOL shouldDelete = YES;
    
    if ([UITextField instancesRespondToSelector:_cmd]) {
        BOOL (*keyboardInputShouldDelete)(id, SEL, UITextField *) = (BOOL (*)(id, SEL, UITextField *))[UITextField instanceMethodForSelector:_cmd];
        
        if (keyboardInputShouldDelete) {
            shouldDelete = keyboardInputShouldDelete(self, _cmd, textField);
        }
    }
    
    if (![textField.text length] && [[[UIDevice currentDevice] systemVersion] intValue] >= 8) {
        [self deleteBackward];
    }
    
    return shouldDelete;
}

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
