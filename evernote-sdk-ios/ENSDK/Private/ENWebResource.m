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

#import "ENWebResource.h"

NSString * const ENWebResourceTextEncodingNameUTF8 = @"UTF-8";

static NSString * const ENWebResourceDictionaryDataKey = @"WebResourceData";
static NSString * const ENWebResourceDictionaryURLKey = @"WebResourceURL";
static NSString * const ENWebResourceDictionaryMIMETypeKey = @"WebResourceMIMEType";
static NSString * const ENWebResourceDictionaryTextEncodingNameKey = @"WebResourceTextEncodingName";
static NSString * const ENWebResourceDictionaryFrameNameKey = @"WebResourceFrameName";

@interface ENWebResource ()
@property (nonatomic, strong) NSData * data;
@property (nonatomic, strong) NSURL * URL;
@property (nonatomic, copy) NSString * MIMEType;
@property (nonatomic, copy) NSString * textEncodingName;
@property (nonatomic, copy) NSString * frameName;
@end

@implementation ENWebResource
+ (ENWebResource *)webResourceWithDictionary:(NSDictionary *)dictionary
{
    return [[ENWebResource alloc] initWithData:dictionary[ENWebResourceDictionaryDataKey]
                                           URL:[NSURL URLWithString:dictionary[ENWebResourceDictionaryURLKey]]
                                      MIMEType:dictionary[ENWebResourceDictionaryMIMETypeKey]
                              textEncodingName:dictionary[ENWebResourceDictionaryTextEncodingNameKey]
                                     frameName:dictionary[ENWebResourceDictionaryFrameNameKey]];
}

- (id)initWithData:(NSData *)data URL:(NSURL *)URL MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName frameName:(NSString *)frameName
{
    self = [super init];
    if (self) {
        self.data = data;
        self.URL = URL;
        self.MIMEType = MIMEType;
        self.textEncodingName = textEncodingName;
        self.frameName = frameName;
    }
    return self;
}

- (id)propertyList
{
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    if (self.data) {
        dictionary[ENWebResourceDictionaryDataKey] = self.data;
    }
    if (self.URL) {
        dictionary[ENWebResourceDictionaryURLKey] = [self.URL absoluteString];
    }
    if (self.MIMEType) {
        dictionary[ENWebResourceDictionaryMIMETypeKey] = self.MIMEType;
    }
    if (self.textEncodingName) {
        dictionary[ENWebResourceDictionaryTextEncodingNameKey] = self.textEncodingName;
    }
    if (self.frameName) {
        dictionary[ENWebResourceDictionaryFrameNameKey] = self.frameName;
    }
    return dictionary;
}
@end
