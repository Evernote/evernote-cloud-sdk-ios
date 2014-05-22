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
@class ENNote;
@class ENResource;
@class ENNotebook;
@class UIWebView;

extern NSString * const ENWebArchiveDataMIMEType;

typedef void (^ENNotePopulateFromWebViewCompletionHandler)(ENNote * note);
typedef void (^ENNoteGenerateWebArchiveDataCompletionHandler)(NSData * data);

@interface ENNote : NSObject
@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) ENNoteContent * content;
@property (nonatomic, copy) NSArray * tagNames;
@property (nonatomic, assign) BOOL isReminder;
- (NSArray *)resources;
- (void)addResource:(ENResource *)resource;
- (void)removeAllResources;

- (void)generateWebArchiveData:(ENNoteGenerateWebArchiveDataCompletionHandler)completion;
+ (void)populateNoteFromWebView:(UIWebView *)webView completion:(ENNotePopulateFromWebViewCompletionHandler)completion;
@end
