/*
 * Copyright (c) 2012-2014 by Evernote Corporation, All rights reserved.
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

#import "ENXMLDTD.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ENXMLWriterDelegate;

@interface ENXMLWriter : NSObject

@property (weak, nonatomic, nullable) id<ENXMLWriterDelegate> delegate;

@property (strong, nonatomic, nullable) ENXMLDTD *dtd;
@property (assign, nonatomic) NSUInteger openElementCount;
@property (strong, readonly, nonatomic, nullable) NSString *contents;

- (id) initWithDelegate:(nullable id<ENXMLWriterDelegate>)delegate NS_DESIGNATED_INITIALIZER; 

- (void) startDocument;
- (void) endDocument;

// Returns NO if the element is not valid in the
// given DTD.
- (BOOL)startElement:(NSString *)element NS_SWIFT_NAME(start(element:));
- (BOOL)startElement:(NSString *)element
          attributes:(nullable NSDictionary<NSString *, NSString *> *)attributes NS_SWIFT_NAME(start(element:attributes:));

- (BOOL) startElement:(NSString*)element
       withAttributes:(nullable NSDictionary<NSString *, NSString *>*)attrDict
    DEPRECATED_MSG_ATTRIBUTE("Use -startElement:attributes: instead.") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void) endElement;

// Returns NO if the element is not valid in the
// given DTD.
- (BOOL)writeElement:(NSString *)element
          attributes:(nullable NSDictionary<NSString *, NSString *> *)attributes
             content:(nullable NSString *)content NS_SWIFT_NAME(write(element:attributes:content:));

- (BOOL) writeElement:(NSString *)element
       withAttributes:(nullable NSDictionary<NSString *, NSString *> *)attributes
              content:(nullable NSString *)content
    DEPRECATED_MSG_ATTRIBUTE("Use -writeElement:attributes:content instead.") NS_SWIFT_UNAVAILABLE("Deprecated");

// Write an attribute.  The assumption here is that the attribute value has 
// *not* been escaped: e.g. foo&bar not foo&amp;bar
// Returns NO if the attribute is not valid for
// the current element in the DTD.
- (BOOL) writeAttributeName:(NSString*)attributeName
                      value:(NSString*)value NS_SWIFT_NAME(write(attributeName:value:));

// Write a raw string.  No escaping is performed.
- (void) writeRawString:(nullable NSString *)rawString NS_SWIFT_NAME(write(rawString:));

// Write a string.  Escaping is performed.
- (void) writeString:(nullable NSString *)string;

- (void) startCDATA;
- (void) writeCDATA:(NSString *)CDATA NS_SWIFT_NAME(write(CDATA:));
- (void) endCDATA;

@end


@protocol ENXMLWriterDelegate <NSObject>
- (void) xmlWriter:(ENXMLWriter *)writer didGenerateData:(NSData*)data;
- (void) xmlWriterDidEndWritingDocument:(ENXMLWriter *)writer;
@end


NS_ASSUME_NONNULL_END
