//
//  CommonUtils.m
//  evernote-sdk-ios
//
//  Created by Eric Cheng on 11/17/14.
//  Copyright (c) 2014 Evernote Corporation. All rights reserved.
//

#import "CommonUtils.h"

@implementation CommonUtils

+ (void)showSimpleAlertWithMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
