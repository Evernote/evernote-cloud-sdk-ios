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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  This class represents a resource attached to an Evernote note. A resource is often an image,
 *  but can be any file with any MIME type. The resource is typically referred to from within the 
 *  note content.
 */
@interface ENResource : NSObject

/**
 *  The data body of the resource.
 */
@property (nonatomic, strong) NSData * data;

/**
 *  The MIME type of the resource.
 */
@property (nonatomic, copy) NSString * mimeType;

/**
 *  A filename associated with the resource. This is not required.
 */
@property (nonatomic, copy) NSString * filename;

/**
 *  Designated initializer for a resource.
 *
 *  @param data     The data for this resource.
 *  @param mimeType The MIME type indicating what the data represents.
 *  @param filename (optional) A filename to be associated with the resource.
 *
 *  @return A resouce object instance.
 */
- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename;

/**
 *  Initializer for data and MIME type.
 *
 *  @param data     The data for this resource.
 *  @param mimeType The MIME type indicating what the data represents.
 *
 *  @return A resouce object instance.
 */
- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType;

/**
 *  Convenience initializer for creating a resource directly from an image object. This 
 *  method will choose the smaller of PNG or JPEG encoding, and set the MIME type appropriately.
 *  (If you'd like finer control over the encoding, you can encode the image explicitly and 
 *  use a data initiliazer.)
 *
 *  @param image An image.
 *
 *  @return A resouce object instance.
 */
- (id)initWithImage:(UIImage *)image;

/**
 *  Convenience function to get the ENML media tag for this resource
 *
 *  @return NSString that looks like <en-media width="640" height="480" type="image/jpeg" hash="f03c1c2d96bc67eda02968c8b5af9008"/>
 */
- (NSString*) mediaTag;

@end
