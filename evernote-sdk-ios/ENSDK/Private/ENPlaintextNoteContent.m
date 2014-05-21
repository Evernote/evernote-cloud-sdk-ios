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

#import "ENPlaintextNoteContent.h"
#import "ENSDKPrivate.h"
#import "ENMLWriter.h"

@interface ENPlaintextNoteContent ()
@property (nonatomic, copy) NSString * string;
@end

@implementation ENPlaintextNoteContent
- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        self.string = string;
    }
    return self;
}

- (NSString *)enmlWithResources:(NSArray *)resources
{
    // Wrap each line in a div. Empty lines get <br/>
    // From: http://dev.evernote.com/doc/articles/enml.php "representing plaintext notes"
    ENMLWriter * writer = [[ENMLWriter alloc] init];
    [writer startDocument];
    for (NSString * line in [self.string componentsSeparatedByString:@"\n"]) {
        [writer startElement:@"div"];
        if (line.length == 0) {
            [writer writeElement:@"br" withAttributes:nil content:nil];
        } else {
            [writer writeString:line];
        }
        [writer endElement];
    }
    for (ENResource * resource in resources) {
        [writer writeResourceWithDataHash:resource.dataHash mime:resource.mimeType attributes:nil];
    }
    [writer endDocument];
    return writer.contents;
}
@end
