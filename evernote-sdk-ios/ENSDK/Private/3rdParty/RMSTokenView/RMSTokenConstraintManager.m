//
// Created by Christian Di Lorenzo on 8/31/13.
// Copyright (c) 2013 RoleModel Software. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "RMSTokenConstraintManager.h"
#import "RMSTokenView.h"
#import "ENTheme.h"

const CGFloat RMSTokenLineHeight = 43;
RMSTokenConstraintManager *sharedManager;

@interface RMSTokenConstraintManager()
@property (nonatomic, strong) NSMutableArray *updatingConstraints;
@end

@implementation RMSTokenConstraintManager

+ (id)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[RMSTokenConstraintManager alloc] init];
    });
    return sharedManager;
}

- (void)setupHeightConstraintFromOutlet:(NSLayoutConstraint *)heightConstraint {
    if (!heightConstraint) {
        self.heightConstraint = [NSLayoutConstraint constraintWithItem:self.tokenView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:RMSTokenLineHeight + 1];
        [self.tokenView addConstraint:self.heightConstraint];
    } else {
        self.heightConstraint = heightConstraint;
    }
}

- (void)setupContentViewConstraints:(UIView *)contentView {
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSString *format in @[@"H:|[view]|", @"V:|[view]|"]) {
        [self addConstraintsWithFormat:format withView:contentView toView:self.tokenView];
    }
    self.tokenContentView = contentView;
}

- (void)setupLineViewConstraints:(UIView *)lineView {
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraintsWithFormat:@"H:|[view]|" withView:lineView toView:self.tokenContentView];
}

- (void)setupConstraintsOnTextField:(UITextField *)textField {
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraintsWithFormat:@"V:[view(43)]" withView:textField toView:textField];
    [textField setContentHuggingPriority:100 forAxis:UILayoutConstraintAxisHorizontal];
    [self addConstraintsWithFormat:@"H:[view]-6@900-|" withView:textField toView:self.tokenContentView];
}

- (void)setupConstraintsOnToken:(UIButton *)tokenView {
    tokenView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)updateConstraintsForTokenLines:(NSArray *)tokenLines andLineView:(UIView *)lineView withTextFieldFocus:(BOOL)textFieldHasFocus isSearching:(BOOL)isSearching {
    if (self.updatingConstraints) {
        [self.tokenContentView removeConstraints:self.updatingConstraints];
    }

    self.updatingConstraints = [NSMutableArray array];

    UIView *lastView = nil;
    CGFloat topOffset = 0.0;
    UILayoutPriority compressionResistance = UILayoutPriorityDefaultHigh;

    for (NSArray *line in tokenLines) {
        for (UIView *tokenView in line) {
            if (!lastView) {
                [self.updatingConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[tokenView]->=6-|" options:(NSLayoutFormatOptions)0 metrics:nil views:NSDictionaryOfVariableBindings(tokenView)]];
            } else {
                [self.updatingConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastView]-6-[tokenView]" options:(NSLayoutFormatOptions)0 metrics:nil views:NSDictionaryOfVariableBindings(tokenView, lastView)]];
            }
            [self.updatingConstraints addObject:[NSLayoutConstraint constraintWithItem:tokenView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.tokenContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:topOffset + RMSTokenLineHeight / 2.0]];

            [tokenView setContentCompressionResistancePriority:compressionResistance forAxis:UILayoutConstraintAxisHorizontal];

            lastView = tokenView;
            compressionResistance -= 1;
        }

        lastView = nil;
        topOffset += RMSTokenLineHeight - 8.0;
    }

    [self.updatingConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[lineView(%f)]|", OnePxHeight()] options:(NSLayoutFormatOptions)0 metrics:nil views:NSDictionaryOfVariableBindings(lineView)]];

    self.tokenView.contentSize = CGSizeMake(self.tokenView.contentSize.width, topOffset + 9.0);

    if (self.heightConstraint.constant != self.tokenView.contentSize.height) {
        self.heightConstraint.constant = self.tokenView.contentSize.height;
    }

    [self.updatingConstraints addObject:[NSLayoutConstraint constraintWithItem:self.tokenContentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.tokenView.contentSize.height]];
    [self.updatingConstraints addObject:[NSLayoutConstraint constraintWithItem:self.tokenContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.tokenView.contentSize.width]];

    [self.tokenContentView addConstraints:self.updatingConstraints];
}

#pragma mark Constraint Helpers

- (void)addConstraintsWithFormat:(NSString *)format withView:(UIView *)view toView:(UIView *)superview {
    [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:@{@"view": view}]];
}

@end
