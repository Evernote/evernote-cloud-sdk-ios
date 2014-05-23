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

#import "ENLinkedNotebookRef.h"

@implementation ENLinkedNotebookRef
+ (ENLinkedNotebookRef *)linkedNotebookRefFromLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
{
    ENLinkedNotebookRef * linkedNotebookRef = [[ENLinkedNotebookRef alloc] init];
    linkedNotebookRef.guid = linkedNotebook.guid;
    linkedNotebookRef.noteStoreUrl = linkedNotebook.noteStoreUrl;
    linkedNotebookRef.shardId = linkedNotebook.shardId;
    linkedNotebookRef.sharedNotebookGlobalId = linkedNotebook.sharedNotebookGlobalId;
    return linkedNotebookRef;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.guid = [decoder decodeObjectForKey:@"guid"];
        self.noteStoreUrl = [decoder decodeObjectForKey:@"noteStoreUrl"];
        self.shardId = [decoder decodeObjectForKey:@"shardId"];
        self.sharedNotebookGlobalId = [decoder decodeObjectForKey:@"sharedNotebookGlobalId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.noteStoreUrl forKey:@"noteStoreUrl"];
    [encoder encodeObject:self.shardId forKey:@"shardId"];
    [encoder encodeObject:self.sharedNotebookGlobalId forKey:@"sharedNotebookGlobalId"];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    ENLinkedNotebookRef * other = object;
    if ((other.guid == self.guid || [other.guid isEqualToString:self.guid]) &&
        (other.noteStoreUrl == self.noteStoreUrl || [other.noteStoreUrl isEqualToString:self.noteStoreUrl]) &&
        (other.shardId == self.shardId || [other.shardId isEqualToString:self.shardId]) &&
        (other.sharedNotebookGlobalId == self.sharedNotebookGlobalId || [other.sharedNotebookGlobalId isEqualToString:self.sharedNotebookGlobalId])) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [self.guid hash];
    result = prime * result + [self.noteStoreUrl hash];
    result = prime * result + [self.shardId hash];
    result = prime * result + [self.sharedNotebookGlobalId hash];
    return result;
}
@end
