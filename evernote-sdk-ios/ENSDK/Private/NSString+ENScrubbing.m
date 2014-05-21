/*
 * Copyright (c) 2009-2014 by Evernote Corporation, All rights reserved.
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

#import "NSString+ENScrubbing.h"

@implementation NSString (ENScrubbing)

- (NSString *)en_scrubUsingRegex:(NSString *)regexPattern
                   withMinLength:(uint16_t)minLength
                       maxLength:(uint16_t)maxLength
     invalidCharacterReplacement:(NSString *)replacement
{
    NSString * string = self;
    if ([string length] < minLength) {
        return nil;
    }
    else if ([string length] > maxLength) {
        string = [string substringToIndex:maxLength];
    }
    
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:NULL];
    NSArray * matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (matches.count == 0) {
        NSMutableString * newString = [NSMutableString stringWithCapacity:[string length]];
        for (NSUInteger i = 0; i < [string length]; i++) {
            NSString * oneCharSubString = [string substringWithRange:NSMakeRange(i, 1)];
            matches = [regex matchesInString:oneCharSubString options:0 range:NSMakeRange(0, 1)];
            if (matches.count > 0) {
                [newString appendString:oneCharSubString];
            } else if (replacement != nil) {
                [newString appendString:replacement];
            }
        }
        string = newString;
    }
    
    if ([string length] < minLength) {
        return nil;
    }
    
    return string;
}

- (NSString *)en_scrubUsingRegex:(NSString *)regexPattern
                   withMinLength:(uint16_t)minLength
                       maxLength:(uint16_t)maxLength
{
    return [self en_scrubUsingRegex:regexPattern
                      withMinLength:minLength
                          maxLength:maxLength
        invalidCharacterReplacement:nil];
}

@end
