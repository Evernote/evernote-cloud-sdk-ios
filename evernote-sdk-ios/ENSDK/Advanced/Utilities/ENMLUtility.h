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

@class EDAMResource;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ENMLToHTMLCompletionBlock)(NSString *_Nullable html, NSError *_Nullable error);

/** Utility methods to work with ENML.
 */
@interface ENMLUtility : NSObject <NSXMLParserDelegate>

/** Utility function to create an enml media tag.
 
 @param  dataHash The md5 hash of the data
 @param  mime The mime type of the data
 */
+ (NSString*) mediaTagWithDataHash:(NSData *)dataHash
                              mime:(nullable NSString *)mime NS_SWIFT_NAME(mediaTagWith(dataHash:mime:));


/** Utility function to convert ENML to HTML.
 
 @param  enml The enml content of the note
 @param  completion The completion block that will be called on completion
 */
- (void)generateHTMLFromENML:(NSString *)enml completion:(ENMLToHTMLCompletionBlock)completion NS_SWIFT_NAME(generateHTMLFrom(enml:completion:));

- (void) convertENMLToHTML:(NSString*)enmlContent completionBlock:(ENMLToHTMLCompletionBlock)block
    DEPRECATED_MSG_ATTRIBUTE("Use -generateHTMLFromENML:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

/** Utility function to convert ENML to HTML.
 
 @param  enml The enml content of the note
 @param  inlinedResources Array of EDAM resources, which will be inlined into the resulting HTML.
 @param  completion The completion block that will be called on completion
 */
- (void)generateHTMLFromENML:(NSString *)enml
            inlinedResources:(nullable NSArray<EDAMResource *> *)inlinedResources
                  completion:(ENMLToHTMLCompletionBlock)completion NS_SWIFT_NAME(generateHTMLFrom(enml:inlinedResources:completion:));
- (void) convertENMLToHTML:(NSString*)enmlContent withInlinedResources:(nullable NSArray<EDAMResource *> *)resources completionBlock:(ENMLToHTMLCompletionBlock)block
    DEPRECATED_MSG_ATTRIBUTE("Use -generateHTMLFromENML:inlinedResources:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

/** Utility function to convert ENML to HTML.
 
 @param  enml The enml content of the note
 @param  referencedResources Array of EDAM resources, which will be referenced in the resulting HTML using the sourceURL property.
 @param  completion The completion block that will be called on completion
 */
- (void)generateHTMLFromENML:(NSString *)enml
         referencedResources:(nullable NSArray<EDAMResource *> *)referencedResources
                  completion:(ENMLToHTMLCompletionBlock)completion NS_SWIFT_NAME(generateHTMLFrom(enml:referencedResources:completion:));
- (void) convertENMLToHTML:(NSString*)enmlContent withReferencedResources:(nullable NSArray<EDAMResource *> *)resources completionBlock:(ENMLToHTMLCompletionBlock)block
    DEPRECATED_MSG_ATTRIBUTE("Use -generateHTMLFromENML:referencedResources:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

@end

NS_ASSUME_NONNULL_END
