//
//  RMSTextField.h
//  RMSTokenView
//
//  Created by Patrick Strawderman on 5/5/14.
//  Copyright (c) 2014 RoleModel Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BackspaceDelegate <NSObject>

@optional
- (void)willDeleteBackward:(UITextField*)textField;
- (void)didDeleteBackward:(UITextField*)textField;

@end


@interface RMSTextField : UITextField
@property (nonatomic, weak) id<BackspaceDelegate>backspaceDelegate;
@end
