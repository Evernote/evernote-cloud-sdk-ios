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
#import "NSData+EvernoteSDK.h"
#import "ENMLUtility.h"

@interface ENResource ()
@property (nonatomic, copy) NSString * sourceUrl;
@property (nonatomic, strong) NSData * dataHash;
@property (nonatomic, strong) NSDictionary * edamAttributes;
@property (nonatomic, copy) NSString * guid;
@end

@implementation ENResource
+ (instancetype)resourceWithServiceResource:(EDAMResource *)serviceResource
{
    if (!serviceResource.data.body) {
        ENSDKLogError(@"Can't create an ENResource from an EDAMResource with no body");
        return nil;
    }
    ENResource * resource = [[ENResource alloc] init];
    resource.data = serviceResource.data.body;
    resource.mimeType = serviceResource.mime;
    resource.filename = serviceResource.attributes.fileName;
    resource.sourceUrl = serviceResource.attributes.sourceURL;
    resource.guid = serviceResource.guid;
    return resource;
}

- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename
{
    self = [super init];
    if (self) {
        self.data = data;
        self.mimeType = mimeType;
        self.filename = filename;

        if (!self.data) {
            return nil;
        }
    }
    return self;
}

- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType
{
    return [self initWithData:data mimeType:mimeType filename:nil];
}

- (id)initWithImage:(UIImage *)image
{
    // Encode both ways and use the smaller of the two. Ties goes to (lossless) PNG.
    NSData * pngData = UIImagePNGRepresentation(image);
    NSData * jpegData = UIImageJPEGRepresentation(image, 0.7);
    if (jpegData.length < pngData.length) {
        pngData = nil;
        return [self initWithData:jpegData mimeType:[EDAMLimitsConstants EDAM_MIME_TYPE_JPEG]];
    } else {
        jpegData = nil;
        return [self initWithData:pngData mimeType:[EDAMLimitsConstants EDAM_MIME_TYPE_PNG]];
    }
}

- (void)setData:(NSData *)data
{
    if (data && data.length >= INT32_MAX) {
        ENSDKLogError(@"Data length for resource is greater than int32.");
        data = nil;
    }

    self.dataHash = nil;
    _data = data;
}

- (NSData *)dataHash
{
    // Compute and cache the hash value.
    if (!_dataHash && self.data.length > 0) {
        _dataHash = [self.data enmd5];
    }
    return _dataHash;
}

- (EDAMResource *)EDAMResource
{
    if (!self.data) {
        return nil;
    }
    
    EDAMResource * resource = [[EDAMResource alloc] init];
    if (self.data) {
        resource.data = [[EDAMData alloc] init];
        resource.data.bodyHash = self.dataHash;
        resource.data.size = @(self.data.length);
        resource.data.body = self.data;
    }
    resource.mime = self.mimeType;
    EDAMResourceAttributes * attributes = [[EDAMResourceAttributes alloc] init];
    if (self.filename) {
        attributes.fileName = self.filename;
    }
    if (self.sourceUrl) {
        attributes.sourceURL = self.sourceUrl;
    }
    
    resource.attributes = attributes;
    
    // set EDAM attributes if edamAttributes dictionary is not nil
    for (NSString * key in self.edamAttributes.allKeys) {
        id value = [self.edamAttributes valueForKey:key];
        @try {
            [resource.attributes setValue:value forKey:key];
        }
        @catch (NSException *exception) {
            ENSDKLogError(@"Unable to set value %@ for key %@ on EDAMResource.attributes", value, key);
            if ([[exception name] isEqualToString: NSUndefinedKeyException]) {
                ENSDKLogError(@"Key %@ not found on EDAMResource.attributes", key);
            }
        }
    }

    return resource;
}

- (NSString*) mediaTag
{
    return [ENMLUtility mediaTagWithDataHash:self.dataHash mime:self.mimeType];
}

@end
