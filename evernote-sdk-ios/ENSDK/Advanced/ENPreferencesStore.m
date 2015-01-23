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

#import "ENPreferencesStore.h"
#import "ENSDKPrivate.h"

static NSString * ENPreferencesStoreFilename = @"com.evernote.evernote-sdk-ios.plist";

@interface ENPreferencesStore ()
@property (nonatomic, strong) NSString * pathname;
@property (nonatomic, strong) NSMutableDictionary * store;
@end

@implementation ENPreferencesStore
+ (NSString *)pathnameForStoreFilename:(NSString *)filename
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [[paths[0] stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:filename];
}

- (id)initWithStoreFilename:(NSString *)filename
{
    self = [super init];
    if (self) {
        self.pathname = [[self class] pathnameForStoreFilename:filename];
        [self load];
    }
    return self;
}

- (id)initWithURL:(NSURL*)fileURL
{
    self = [super init];
    if (self) {
        self.pathname = [fileURL path];
        [self load];
    }
    return self;
}

- (id)init
{
    [NSException raise:NSInvalidArgumentException format:@"Must call -initWithStoreFilename:"];
    return nil;
}

+(instancetype) preferenceStoreWithSecurityApplicationGroupIdentifier:(NSString*)groupId
{
    NSURL* URL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupId];
    return [[self alloc] initWithURL:[URL URLByAppendingPathComponent:ENPreferencesStoreFilename]];
}

+(instancetype) defaultPreferenceStore
{
    return [[self alloc] initWithStoreFilename:ENPreferencesStoreFilename];
}

- (id)objectForKey:(NSString *)key
{
    @synchronized(self) {
        return [self.store objectForKey:key];
    }
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    @synchronized(self) {
        if (object) {
            [self.store setObject:object forKey:key];
        } else {
            [self.store removeObjectForKey:key];
        }
    }
    [self save];
}

- (id)decodedObjectForKey:(NSString *)key
{
    NSData * data = nil;
    @synchronized(self) {
        data = [self.store objectForKey:key];
    }
    if (!data || ![data isKindOfClass:[NSData class]]) {
        return nil;
    }
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } @catch(id e) {
        NSLog(@"ENPreferencesStore: Error unarchiving object for key %@ : %@", key, e);
        // DON'T nuke whatever object this is, maybe the called called the wrong
        // getter.
    }
    
    return object;
}

- (void)encodeObject:(id)object forKey:(NSString *)key
{
    NSData * data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
    } @catch(id e) {
        NSLog(@"ENPreferencesStore: Error archiving object of root class %@ : %@", [object class], e);
    }
    if (data) {
        @synchronized(self) {
            [self.store setObject:data forKey:key];
        }
        [self save];
    }
}

- (void)save
{
    NSMutableDictionary * store = nil;
    @synchronized(self) {
        store = self.store;
    }
    NSError * error = nil;
    NSData * data = [NSPropertyListSerialization dataWithPropertyList:store format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!data) {
        NSLog(@"ENPreferencesStore: Error serializing prefs store. %@", error);
    }
    if (data) {
        if (![data writeToFile:self.pathname options:NSDataWritingAtomic error:&error]) {
            NSLog(@"ENPreferencesStore: Error writing prefs store. %@", error);
        }
    }
}

- (void)removeAllItems
{
    @synchronized(self) {
        [self.store removeAllObjects];
    }
    [self save];
}

- (void)load
{
    NSMutableDictionary * prefs = nil;

    NSError * error = nil;
    NSData * data = [NSData dataWithContentsOfFile:self.pathname options:0 error:&error];
    if (data) {
        NSPropertyListFormat format;
        prefs = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:&format error:&error];
        if (!prefs || format != NSPropertyListXMLFormat_v1_0) {
            // File was there but failed to deserialize. That's worth logging.
            NSLog(@"ENPreferencesStore: Failed to open preferences store at %@: %@", self.pathname, error);
            prefs = nil;
        }
    }
    if (!prefs) {
        [[NSFileManager defaultManager] removeItemAtPath:self.pathname error:NULL];
        prefs = [[NSMutableDictionary alloc] init];
    }
    @synchronized(self) {
        self.store = prefs;
    }
}
@end
