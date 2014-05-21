//
// Created by Christian Di Lorenzo on 8/31/13.
// Copyright (c) 2013 RoleModel Software. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>
@class RMSTokenView;

@interface RMSTokenConstraintManager : NSObject

@property (nonatomic, weak) RMSTokenView *tokenView;
@property (nonatomic, weak) UIView *tokenContentView;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

+ (id)manager;

- (void)setupHeightConstraintFromOutlet:(NSLayoutConstraint *)heightConstraint;
- (void)setupContentViewConstraints:(UIView *)contentView;
- (void)setupLineViewConstraints:(UIView *)lineView;
- (void)setupConstraintsOnTextField:(UITextField *)textField;
- (void)setupConstraintsOnToken:(UIButton *)tokenView;
- (void)updateConstraintsForTokenLines:(NSArray *)tokenLines andLineView:(UIView *)lineView withTextFieldFocus:(BOOL)textFieldHasFocus isSearching:(BOOL)isSearching;

@end
