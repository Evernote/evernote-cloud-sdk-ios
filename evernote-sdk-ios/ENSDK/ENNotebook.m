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

#import "ENSDKPrivate.h"

@interface ENNotebook ()
@property (nonatomic, strong) EDAMNotebook * notebook;
@property (nonatomic, strong) EDAMLinkedNotebook * linkedNotebook;
@property (nonatomic, strong) EDAMSharedNotebook * sharedNotebook;
@property (nonatomic, assign) BOOL isShared;
@property (nonatomic, assign) BOOL isDefaultNotebookOverride;
@end

@implementation ENNotebook
- (id)initWithNotebook:(EDAMNotebook *)notebook 
{
    return [self initWithNotebook:notebook linkedNotebook:nil sharedNotebook:nil];
}

- (id)initWithSharedNotebook:(EDAMSharedNotebook *)sharedNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
{
    return [self initWithNotebook:nil linkedNotebook:linkedNotebook sharedNotebook:sharedNotebook];
}

- (id)initWithPublicNotebook:(EDAMNotebook *)publicNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
{
    return [self initWithNotebook:publicNotebook linkedNotebook:linkedNotebook sharedNotebook:nil];
}

- (id)initWithSharedNotebook:(EDAMSharedNotebook *)sharedNotebook forLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook withBusinessNotebook:(EDAMNotebook *)notebook
{
    return [self initWithNotebook:notebook linkedNotebook:linkedNotebook sharedNotebook:sharedNotebook];
}

// Designated initializer used by all protected initializers
- (id)initWithNotebook:(EDAMNotebook *)notebook linkedNotebook:(EDAMLinkedNotebook *)linkedNotebook sharedNotebook:(EDAMSharedNotebook *)sharedNotebook
{
    self = [super init];
    if (self) {
        self.notebook = notebook;
        self.linkedNotebook = linkedNotebook;
        self.sharedNotebook = sharedNotebook;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.notebook = [decoder decodeObjectForKey:@"notebook"];
        self.linkedNotebook = [decoder decodeObjectForKey:@"linkedNotebook"];
        self.sharedNotebook = [decoder decodeObjectForKey:@"sharedNotebook"];
        self.isShared = [decoder decodeBoolForKey:@"isShared"];
        self.isDefaultNotebookOverride = [decoder decodeBoolForKey:@"isDefaultNotebookOverride"];
        if (!self.notebook && !self.linkedNotebook && !self.sharedNotebook) {
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.notebook forKey:@"notebook"];
    [encoder encodeObject:self.linkedNotebook forKey:@"linkedNotebook"];
    [encoder encodeObject:self.sharedNotebook forKey:@"sharedNotebook"];
    [encoder encodeBool:self.isShared forKey:@"isShared"];
    [encoder encodeBool:self.isDefaultNotebookOverride forKey:@"isDefaultNotebookOverride"];
}

- (NSString *)name
{
    if (self.notebook) {
        return self.notebook.name;
    } else {
        return self.linkedNotebook.shareName;
    }
}

- (NSString *)ownerDisplayName
{
    NSString * ownerName = nil;
    if (self.isBusinessNotebook) {
        ownerName = self.notebook.contact.name;
        if (ownerName.length == 0) {
            ownerName = [[ENSession sharedSession] businessDisplayName];
        }
    } else if (self.linkedNotebook) {
        ownerName = self.linkedNotebook.username;
    } else {
        ownerName = [[ENSession sharedSession] userDisplayName];
    }
    return ownerName;
}

- (NSString *)guid
{
    // Personal notebooks have a native guid, and if we've stashed a public/business-native notebook here, then we can look at that
    // as well.
    if (self.notebook) {
        return self.notebook.guid;
    }
    // Shared notebook objects will also have a notebook GUID on them pointing to their native notebook.
    if (self.sharedNotebook) {
        return self.sharedNotebook.notebookGuid;
    }
    
    return nil;
}

- (BOOL)isShared
{
    return [self isOwnShared] || [self isJoinedShared];
}

- (BOOL)isOwnShared
{
    return ![self isLinked] && [self.notebook.sharedNotebookIds count] > 0;
}

- (BOOL)isJoinedShared
{
    return [self isLinked];
}

- (BOOL)isLinked
{
    return self.linkedNotebook != nil;
}

- (BOOL)isPublic
{
    return [self isOwnPublic] || [self isJoinedPublic];
}

- (BOOL)isJoinedPublic
{
    return [self isLinked] && self.linkedNotebook.sharedNotebookGlobalId == nil;
}

- (BOOL)isOwnPublic {
    return ![self isLinked] && [self.notebook.publishing.uri length] > 0;
}

- (BOOL)isBusinessNotebook
{
    // Business notebooks are the only ones that have a combination of a linked notebook and normal
    // notebook being set. In this case, the normal notebook represents the notebook inside the business.
    // additionally, checking linked notebook record is actually pointing to a shared notebook record so it's not a public notebook
    return self.notebook != nil && self.linkedNotebook != nil && self.linkedNotebook.sharedNotebookGlobalId != nil;
}

- (BOOL)isOwnedByUser
{
    // If there's no linked record, the notebook exists in the primary account, which means owned by user.
    if (!self.linkedNotebook) {
        return YES;
    }
    
    // If it's not a business notebook, but it is linked, then it's definitely NOT owned by the user.
    if (![self isBusinessNotebook]) {
        return NO;
    }
    
    // Business notebooks are a little trickier. They are always linked, because technically the business owns
    // them. What we really want to know is whether the contact user is the same as the current user.
    return ([self.notebook.contact.id intValue] == [[ENSession sharedSession] userID]);
}

- (BOOL)isDefaultNotebook
{
    if (self.isDefaultNotebookOverride) {
        return YES;
    } else if (self.notebook && [self isJoinedPublic] == NO) {
        return [self.notebook.defaultNotebook boolValue];
    }
    return NO;
}

- (BOOL)allowsWriting
{
    if (!self.linkedNotebook) {
        // All personal notebooks are readwrite.
        return YES;
    }
    
    if ([self isJoinedPublic]) {
        // All public notebooks are readonly.
        return NO;
    }
    
    int privilege = [self.sharedNotebook.privilege intValue];
    if (privilege == SharedNotebookPrivilegeLevel_GROUP) {
        // Need to consult the business notebook object privilege.
        privilege = [self.notebook.businessNotebook.privilege intValue];
    }
    
    if (privilege == SharedNotebookPrivilegeLevel_MODIFY_NOTEBOOK_PLUS_ACTIVITY ||
        privilege == SharedNotebookPrivilegeLevel_FULL_ACCESS ||
        privilege == SharedNotebookPrivilegeLevel_BUSINESS_FULL_ACCESS) {
        return YES;
    }
    
    return NO;
}

- (NSString *)description
{
    NSMutableString * owner = [NSMutableString stringWithFormat:@"\"%@\"", [self ownerDisplayName]];
    if (self.isOwnedByUser) {
        [owner appendString:@" (me)"];
    }
    return [NSString stringWithFormat:@"<%@: %p; name = \"%@\"; business = %@; shared = %@; owner = %@; access = %@>",
            [self class], self, self.name, self.isBusinessNotebook ? @"YES" : @"NO", self.isShared ? @"YES" : @"NO", owner,
            self.allowsWriting ? @"R/W" : @"R/O"];
}

- (BOOL)isEqual:(id)object
{
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [self.guid isEqualToString:((ENNotebook *)object).guid];
}

- (NSUInteger)hash
{
    return [self.guid hash];
}
@end
