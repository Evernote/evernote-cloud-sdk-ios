//
//  RMSTokenView.m
//  RMSTokenView
//
//  Created by Christian Di Lorenzo on 8/31/13.
//  Copyright (c) 2013 RoleModel Software. All rights reserved.
//

#import "RMSTokenView.h"
#import "RMSTokenConstraintManager.h"
#import "ENTheme.h"

@interface RMSTokenView()
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) NSMutableArray *tokenViews;
@property (nonatomic, strong) NSMutableArray *tokenLines;
@property (nonatomic, strong) UIButton *selectedToken;

@property (nonatomic) CGSize lastKnownSize;

@property (nonatomic, strong) RMSTokenConstraintManager *constraintManager;

#pragma mark - Token View
@property (nonatomic) CGFloat tokenViewBorderRadius;
@property (nonatomic) BOOL needsGradient;

@end

@implementation RMSTokenView

#pragma mark - Setup

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.tokenViewBorderRadius = 12;
    if (CGRectIsEmpty(self.frame)) {
        self.frame = CGRectMake(0, 0, 320, 44);
    }
    self.contentSize = self.bounds.size;
    self.clipsToBounds = YES;
    
    _tokenViews = [NSMutableArray array];
    _tokenLines = [NSMutableArray arrayWithObject:[NSMutableArray array]];
    
    _constraintManager = [RMSTokenConstraintManager manager];
    _constraintManager.tokenView = self;
    
    [self setupViews];
}

- (void)setupViews {
    if (!self.heightConstraint) {
        for (NSLayoutConstraint *constraint in self.constraints) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                self.heightConstraint = constraint;
                break;
            }
        }
    }
    [self.constraintManager setupHeightConstraintFromOutlet:self.heightConstraint];

    self.content = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.content];
    [self.constraintManager setupContentViewConstraints:self.content];

    self.lineView = [[UIView alloc] init];
    self.lineView.backgroundColor = [ENTheme defaultSeparatorColor];
    [self.content addSubview:self.lineView];
    [self.constraintManager setupLineViewConstraints:self.lineView];

    RMSTextField *textField = [[RMSTextField alloc] init];
    textField.backspaceDelegate = self;
    textField.delegate = self;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField = textField;
    [self.content addSubview:textField];
    [self.constraintManager setupConstraintsOnTextField:textField];
    [[self.tokenLines lastObject] addObject:textField];

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewSelected:)]];
}

- (void)dealloc {
    self.textField.delegate = nil;
}

- (void)willDeleteBackward:(UITextField *)textField {
    if (self.selectedToken) {
        [self removeTokenWithText:[self.selectedToken titleForState:UIControlStateNormal]];
        [self selectTokenWithText:nil];
    } else if (self.tokens.count) {
        if (textField.text.length == 0 ||
            (textField.selectedTextRange.empty &&
             [textField offsetFromPosition:textField.beginningOfDocument
                                toPosition:textField.selectedTextRange.start] == 0)) {
                [self selectLastToken];
            }
    }
}

#pragma mark - Actions

- (void)addTokenTextToBeSanitized: (NSString *)tokenText {
    [self addTokenWithText:[tokenText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)addTokenWithText:(NSString *)tokenText {
    if ([tokenText length] == 0) return;
    if ([self.tokens containsObject:tokenText]) {
        [self selectTokenWithText:tokenText];
        self.text = nil;
        return;
    }
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:shouldAddTokenWithText:)]) {
        if (![self.tokenDelegate tokenView:self shouldAddTokenWithText:tokenText]) {
            return;
        }
    }

    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:willPresentTokenWithText:)]) {
        NSString *transformedText = [self.tokenDelegate tokenView:self willPresentTokenWithText:tokenText];
        if (transformedText) {
            tokenText = transformedText;
        }
    }

    UIButton *tokenView = [UIButton buttonWithType:UIButtonTypeCustom];
    tokenView.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    tokenView.adjustsImageWhenHighlighted = NO;

    UIControlState controlStates[3] = {UIControlStateNormal, UIControlStateHighlighted, UIControlStateSelected};

    for (int idx = 0; idx < 3; idx++) {
        UIControlState controlState = controlStates[idx];
        [tokenView setBackgroundImage:[self tokenBackgroundImageForState:controlState withTokenText:tokenText]
                             forState:controlState];
        [tokenView setAttributedTitle:[[NSAttributedString alloc] initWithString:tokenText attributes:[self titleTextAttributesForState:controlState]]
                             forState:controlState];
    }
    [tokenView setTitle:tokenText forState:UIControlStateNormal];

    [tokenView addTarget:self action:@selector(selectedToken:) forControlEvents:UIControlEventTouchUpInside];
    [self.content addSubview:tokenView];
    [self.constraintManager setupConstraintsOnToken:tokenView];

    [self.tokenViews addObject:tokenView];

    self.text = nil;
    
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didAddTokenWithText:)]) {
        [self.tokenDelegate tokenView:self didAddTokenWithText:tokenText];
    }

    [self updatePlaceholder];
    [self resetLines];
}

- (void)removeTokenWithText:(NSString *)tokenText {
    UIButton *buttonToRemove = nil;
    for (UIButton *tokenButton in self.tokenViews) {
        if ([[tokenButton titleForState:UIControlStateNormal] isEqualToString:tokenText]) {
            buttonToRemove = tokenButton;
            break;
        }
    }

    if (buttonToRemove != nil) {
        [buttonToRemove removeFromSuperview];
        [self.tokenViews removeObject:buttonToRemove];

        if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didRemoveTokenWithText:)]) {
            [self.tokenDelegate tokenView:self didRemoveTokenWithText:tokenText];
        }

        [self updatePlaceholder];
        [self resetLines];
    }
}


- (void)viewSelected:(UITapGestureRecognizer *)tapGesture {
    [self becomeFirstResponder];
    [self selectTokenWithText:nil];
}

- (void)selectedToken:(UIButton *)tokenButton {
    [self selectTokenWithText:[tokenButton titleForState:UIControlStateNormal]];
}

- (void)selectTokenWithText:(NSString *)tokenText {
    if (![[self.selectedToken titleForState:UIControlStateNormal] isEqualToString:tokenText]) {

        self.selectedToken = nil;
        for (UIButton *tokenButton in self.tokenViews) {
            if ([[tokenButton titleForState:UIControlStateNormal] isEqualToString:tokenText]) {
                self.selectedToken = tokenButton;
                break;
            }
        }

        [self updateTextField];
        if (self.selectedToken) {
            [self.textField becomeFirstResponder];
        }
    }

    for (UIButton *tokenView in self.tokenViews) {
        BOOL selected = (tokenView == self.selectedToken);
        if (tokenView.selected != selected) {
            tokenView.selected = selected;
        }
    }

    if (tokenText && [self.tokenDelegate respondsToSelector:@selector(tokenView:didSelectTokenWithText:)]) {
        [self.tokenDelegate tokenView:self didSelectTokenWithText:tokenText];
    }
}

- (void)removeAllTokens {
    [self.tokenViews enumerateObjectsUsingBlock:^(UIButton *buttonToRemove, NSUInteger idx, BOOL *stop) {
        [buttonToRemove removeFromSuperview];
        if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didRemoveTokenWithText:)]) {
            [self.tokenDelegate tokenView:self didRemoveTokenWithText:buttonToRemove.titleLabel.text];
        }
    }];
    
    [self.tokenViews removeAllObjects];

    [self updatePlaceholder];
    [self resetLines];
}

- (void)updateTextField {
    self.textField.hidden = (self.selectedToken || ![self.textField isFirstResponder]);
}

- (void)selectLastToken {
    [self selectTokenWithText:[[self.tokenViews lastObject] titleForState:UIControlStateNormal]];
}

#pragma mark - Searching

- (void)setSearching:(BOOL)searching {
    if (_searching != searching) {
        _searching = searching;

        [self updateConstraints];
        [self.superview layoutIfNeeded];

        [self scrollToBottom];

        if (_searching) {
            self.scrollEnabled = NO;
            self.lineView.hidden = NO;
            self.lineView.backgroundColor = [UIColor colorWithWhite:0.557 alpha:1.000];
        } else {
            self.lineView.backgroundColor = [ENTheme defaultSeparatorColor];
        }
    }
}

- (void)setSearching:(BOOL)searching animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [self setSearching:searching];
        } completion:nil];
    } else {
        [self setSearching:searching];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.content layoutSubviews];

    NSMutableArray *lastLine = [self.tokenLines lastObject];
    [[lastLine copy] enumerateObjectsUsingBlock:^(UIView *tokenView, NSUInteger index, BOOL *stop) {
        if (index != 0) {
            if (tokenView.intrinsicContentSize.width > tokenView.bounds.size.width || (tokenView == self.textField && tokenView.bounds.size.width < 100)) {
                [self.tokenLines addObject:[[lastLine subarrayWithRange:NSMakeRange(index, [lastLine count] - index)] mutableCopy]];
                [lastLine removeObjectsInArray:[self.tokenLines lastObject]];

                [self updateConstraints];
                [self layoutSubviews];

                *stop = YES;
            }
        }
    }];


    /* Content is overflowing horizontally */
    if (self.frame.size.width != self.contentSize.width) {
        self.contentSize = CGSizeMake(self.frame.size.width, self.contentSize.height);
        [self resetLines];
        [self updateConstraints];
        [self layoutSubviews];
        return;
    }

    [self showScrollBarsIfNecessary];
}

- (void)updateConstraints {
    [super updateConstraints];

    [self.constraintManager updateConstraintsForTokenLines:self.tokenLines
                                               andLineView:self.lineView
                                        withTextFieldFocus:[self.textField isFirstResponder]
                                               isSearching:self.searching];

    if (self.searching) {
        [self scrollToBottom];
    }
}

- (void)scrollToBottom {
    self.contentOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
}

- (void)resetLines {
    self.tokenLines = [NSMutableArray arrayWithObject:[self.tokenViews mutableCopy]];
    [[self.tokenLines lastObject] addObject:self.textField];
    [self updateConstraints];
    [self layoutSubviews];
}

- (void)showScrollBarsIfNecessary {
    if (self.textField.isFirstResponder && self.contentSize.height > self.frame.size.height && !self.searching) {
        self.scrollEnabled = YES;
        self.lineView.hidden = YES;
    } else {
        self.scrollEnabled = NO;
        self.lineView.hidden = NO;
    }
}

#pragma mark - Frame Changes

- (void)frameChanged {
    if ([self.tokenLines[0] count] > 0 && self.bounds.size.width != self.lastKnownSize.width) {
        [self resetLines];
    }

    [self showScrollBarsIfNecessary];

    if (self.selectedToken == nil && (self.bounds.size.width != self.lastKnownSize.width || self.bounds.size.height != self.lastKnownSize.height)) {
        [self scrollToBottom];
    }
    self.lastKnownSize = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self frameChanged];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self frameChanged];
}

#pragma mark - First Responder

- (BOOL)canBecomeFirstResponder {
    return [self.textField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    return [self.textField resignFirstResponder];
}

#pragma mark - Text Field Delegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@","]) {
        [self addTokenTextToBeSanitized:self.text];
        return NO;
    }
    if (self.selectedToken) {
        [self removeTokenWithText:[self.selectedToken titleForState:UIControlStateNormal]];
        [self selectTokenWithText:nil];
    }
    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didChangeText:)]) {
        NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        // we call the delegate method on a dispatch queue in case it tries to
        // do something that would update the textField (e.g., adding a token).
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tokenDelegate tokenView:self didChangeText:text];
        });
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self addTokenTextToBeSanitized:self.text];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        self.textField.alpha = 1.0;

        [self setNeedsUpdateConstraints];

        [self scrollToBottom];
    } completion:nil];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self textFieldShouldReturn:textField];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            self.scrollEnabled = NO;
            self.lineView.hidden = NO;
            if (self.tokens.count == 0) {
                [self updatePlaceholder];
            } else {
                self.textField.alpha = 0.0;
            }

            [self setNeedsUpdateConstraints];

            self.contentOffset = CGPointMake(0.0, 0.0);
        } completion:nil];
    });
    return YES;
}

#pragma mark - Token Buttons

- (UIImage *)tokenBackgroundImageForState:(UIControlState)state withTokenText:(NSString *)tokenText {
    UIColor *topColor; UIColor *bottomColor; UIColor *strokeColor;

    if (state == UIControlStateHighlighted || state == UIControlStateSelected) {
        topColor = [ENTheme defaultTintColor];
        bottomColor = [ENTheme defaultTintColor];
        strokeColor = [UIColor colorWithRed:0.110 green:0.451 blue:0.227 alpha:1.0];
    } else {
        topColor = [ENTheme defaultTintColor];
        bottomColor = [ENTheme defaultTintColor];
        strokeColor = [UIColor clearColor];
    }
    return [self buttonImageWithTopColor:topColor bottomColor:bottomColor withStrokeColor:strokeColor];
}

- (NSDictionary *)titleTextAttributesForState:(UIControlState)state {

    if (state == UIControlStateNormal) {
        return @{
                NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0],
                NSForegroundColorAttributeName: [UIColor whiteColor],
        };
    } else if (state == UIControlStateHighlighted) {
        return @{
                NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0],
                NSForegroundColorAttributeName: [UIColor whiteColor],
        };
    } else if (state == UIControlStateSelected) {
        return @{
                NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0],
                NSForegroundColorAttributeName: [UIColor whiteColor],
        };
    }

    return nil;
}

- (UIImage *)buttonImageWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor withStrokeColor:(UIColor *)strokeColor {
    CGRect rect = CGRectMake(0, 0, 29, 25);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    /* Draw Fill Gradient */
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:self.tokenViewBorderRadius].CGPath);
    CGContextClip(context);

    if (self.needsGradient) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat locations[] = {0.0, 1.0};
        NSArray *colors = @[(__bridge id)topColor.CGColor, (__bridge id)bottomColor.CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

        CGPoint startPoint = CGPointMake(rect.size.width / 2.0, 0);
        CGPoint endPoint = CGPointMake(rect.size.width / 2.0, rect.size.height);

        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    } else {
        CGContextSetFillColorWithColor(context, topColor.CGColor);
        UIRectFill(rect);
    }
    
    /* Draw Stroke */
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.2, 0.2) cornerRadius:self.tokenViewBorderRadius].CGPath);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    if ([UIScreen mainScreen].scale == 2.0) {
        CGContextSetLineWidth(context, 1.5);
    } else {
        CGContextSetLineWidth(context, 1.0);
    }
    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 14)];
}

- (void) updatePlaceholder {
    if (self.placeholder) {
        self.textField.placeholder = self.tokens.count == 0 ? self.placeholder : nil;
    }
}

#pragma mark - Accessors

- (void)setText:(NSString *)text
{
    self.textField.text = text;
    self.searching = !!text;

    if ([self.tokenDelegate respondsToSelector:@selector(tokenView:didChangeText:)]) {
        [self.tokenDelegate tokenView:self didChangeText:self.text];
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    [self updatePlaceholder];
}

- (NSString *)text {
    return self.textField.text;
}

- (NSArray *)tokens {
    NSMutableArray *tokens = [NSMutableArray array];
    [self.tokenViews enumerateObjectsUsingBlock:^(UIButton *tokenView, NSUInteger idx, BOOL *stop) {
        [tokens addObject:[tokenView titleForState:UIControlStateNormal]];
    }];
    return tokens;
}

@end
