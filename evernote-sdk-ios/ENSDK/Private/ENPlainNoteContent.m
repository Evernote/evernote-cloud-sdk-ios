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

#import "ENPlainNoteContent.h"
#import "ENSDKPrivate.h"
#import "ENMLWriter.h"

@interface ENPlainNoteContent ()
@property (nonatomic, copy) NSArray * contents;
@end

@implementation ENPlainNoteContent
- (instancetype)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        self.contents = @[string];
    }
    return self;
}

- (instancetype)initWithContents:(NSArray *)contentArray
{
    self = [super init];
    if (self) {
        self.contents = contentArray;
    }
    return self;
}

- (NSString *)enmlWithNote:(ENNote *)note
{
    NSMutableArray *resourcesToAppend = [NSMutableArray array];
    
    // Wrap each line in a div. Empty lines get <br/>
    // From: http://dev.evernote.com/doc/articles/enml.php "representing plaintext notes"
    ENMLWriter * writer = [[ENMLWriter alloc] init];
    [writer startDocument];
    
    for (NSObject *obj in self.contents) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *stringObj = (NSString *)obj;
            for (NSString * line in [stringObj componentsSeparatedByString:@"\n"]) {
                [writer startElement:@"div"];
                if (line.length == 0) {
                    [writer writeElement:@"br" withAttributes:nil content:nil];
                } else {
                    [writer writeString:line];
                }
                [writer endElement];
            }
        }
        if ([obj isKindOfClass:[UIImage class]]) {
            UIImage *imageObj = (UIImage *)obj;
            ENResource *newResource = [[ENResource alloc] initWithImage:imageObj];
            [resourcesToAppend addObject:newResource];
            [writer writeResourceWithDataHash:newResource.dataHash mime:newResource.mimeType attributes:nil];
        }
    }

    // do for remaining resources
    for (ENResource * resource in note.resources) {
        [writer writeResourceWithDataHash:resource.dataHash mime:resource.mimeType attributes:nil];
    }
    [writer endDocument];
    if ([resourcesToAppend count]) {
        [note setResources:[note.resources arrayByAddingObjectsFromArray:resourcesToAppend]];
    }
    
    return writer.contents;
}
@end
