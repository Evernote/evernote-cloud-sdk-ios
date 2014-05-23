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

#import "ENNoteRef.h"
#import "ENLinkedNotebookRef.h"
#import "ENNoteRefInternal.h"

@implementation ENNoteRef
+ (instancetype)noteRefFromData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    id root = nil;
    @try {
        root = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch(id e) {
    }
    if (root && [root isKindOfClass:[self class]]) {
        return root;
    }
    return nil;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = (NSInteger)[decoder decodeInt32ForKey:@"type"];
        self.guid = [decoder decodeObjectForKey:@"guid"];
        self.linkedNotebook = [decoder decodeObjectForKey:@"linkedNotebook"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt32:self.type forKey:@"type"];
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.linkedNotebook forKey:@"linkedNotebook"];
}

- (id)copyWithZone:(NSZone *)zone
{
    ENNoteRef * copy = [[ENNoteRef alloc] init];
    copy.type = self.type;
    copy.guid = self.guid;
    copy.linkedNotebook = self.linkedNotebook;
    return copy;
}

- (NSData *)asData
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    ENNoteRef * other = object;
    if (other.type == self.type &&
        (self.guid == other.guid || [other.guid isEqualToString:self.guid]) &&
        (self.linkedNotebook == other.linkedNotebook || [other.linkedNotebook isEqual:self.linkedNotebook])) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + (int)self.type;
    result = prime * result + [self.guid hash];
    result = prime * result + [self.linkedNotebook hash];
    return result;
}

- (NSString *)description
{
    NSMutableString * str = [[NSMutableString alloc] init];
    NSString * typeStr = nil;
    switch (self.type) {
        case ENNoteRefTypePersonal:
            typeStr = @"personal";
            break;
        case ENNoteRefTypeBusiness:
            typeStr = @"business";
            break;
        case ENNoteRefTypeShared:
            typeStr = @"shared";
            break;
    }
    [str appendFormat:@"<%@: %p; guid = %@; type = %@", [self class], self, self.guid, typeStr];
    if (self.linkedNotebook) {
        [str appendFormat:@"; link shard = %@", self.linkedNotebook.shardId];
    }
    [str appendString:@">"];
    return str;
}
@end
