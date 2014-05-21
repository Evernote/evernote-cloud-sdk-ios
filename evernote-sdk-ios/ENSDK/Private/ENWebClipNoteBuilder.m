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

#import "ENWebClipNoteBuilder.h"
#import "ENSDKPrivate.h"

#import "ENMLConstants.h"
#import "ENWebContentTransformer.h"

#import "ENWebArchive.h"

@interface ENWebClipNoteBuilder()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSURL *url;

@property (copy, nonatomic) void (^completion)(ENNote *);

@end

@implementation ENWebClipNoteBuilder

- (id)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

- (id)initWithWebView:(UIWebView *)webView
{
    self = [super init];
    if (self) {
        self.webView = webView;
    }
    return self;
}

- (void)buildNote:(void (^)(ENNote *))completion {
  self.completion = completion;
  UIWebView *webView = self.webView;
  NSURL *url = self.url;
  
  if (webView != nil) {
    if (url == nil) {
      url = webView.request.URL;
      self.url = url;
    }

    NSString *docType = [webView stringByEvaluatingJavaScriptFromString:@"document.doctype.name"];
    if ([docType isEqualToString:@"html"] == YES) {
      BOOL success = [self clipContentsOfWebView:webView];
      if (success == YES) {
        return;
      }
    }
  }
  
  if (url != nil) {
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                             if (data != nil) {
                               NSString *textEncodingName = [response textEncodingName];
                               if (textEncodingName == nil) {
                                 NSString *mimeType = [response MIMEType];
                                 if (mimeType == nil || [mimeType length] == 0) {
                                   mimeType = ENMIMETypeOctetStream;
                                 }

                                   if ([mimeType isEqualToString:@"text/html"]) {
                                       //XXX assumes utf8 for now. look in <meta> tag?
                                       NSString *htmlString = [[NSString alloc] initWithData:data
                                                                                    encoding:NSUTF8StringEncoding];
                                       if (htmlString != nil) {
                                           [self createNoteFromContents:htmlString
                                                                  title:nil
                                                               mimeType:mimeType
                                                              sourceURL:url];
                                           return;
                                       }
                                   }
                                   
                                 [self createNoteFromContents:data
                                                        title:nil
                                                     mimeType:mimeType
                                                    sourceURL:url];
                                 return;
                               }
                               else {
                                 CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
                                 NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
                                 
                                 NSString *htmlString = [[NSString alloc] initWithData:data
                                                                              encoding:encoding];
                                 if (htmlString != nil) {
                                   [self createNoteFromContents:htmlString
                                                          title:nil
                                                       mimeType:nil
                                                      sourceURL:url];
                                   return;
                                 }
                               }
                             }
                             
                             [self completeWithNote:nil];
                           }];
    return;
  }
  
  [self completeWithNote:nil];
}

#pragma mark -
#pragma mark 
- (void) completeWithNote:(ENNote *)note {
  if (note == nil) {
    self.completion(nil);
  }
  else {
    self.completion(note);
  }
}

- (BOOL) clipContentsOfWebView:(UIWebView *)webView {
  NSString *documentTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  
  NSArray *jsSelectAllLines = @[@"(function() {",
                                @"var selection = window.getSelection();",
                                @"var range = document.createRange();",
                                @"range.selectNodeContents(document.body);",
                                @"selection.removeAllRanges();",
                                @"selection.addRange(range);",
                                @"return JSON.stringify(selection !== null);",
                                @"})();"];
  
  NSString *jsSelectAllCode = [jsSelectAllLines componentsJoinedByString:@"\n"];
  NSString *selectAllResult = [webView stringByEvaluatingJavaScriptFromString:jsSelectAllCode];
  if ([selectAllResult boolValue] == YES) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSArray *oldPasteboardContents = [[pasteboard items] copy];
    
    [webView copy:self];
    ENWebArchive * webArchive = nil;
    NSData * webArchiveData = [pasteboard dataForPasteboardType:ENWebArchivePboardType];
    if (webArchiveData) {
        webArchive = [ENWebArchive webArchiveWithData:webArchiveData];
    }
    pasteboard.items = oldPasteboardContents;
    
    if (webArchive != nil) {
      [self createNoteFromContents:webArchive
                             title:documentTitle
                          mimeType:nil
                         sourceURL:self.url];
      return YES;
    }
  }
  
  // If we made it here, we failed to get a WebArchive...
  NSString *documentSource = [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerHTML"];
  if (documentSource != nil && [documentSource length] > 0) {
    [self createNoteFromContents:documentSource
                           title:documentTitle
                        mimeType:nil
                       sourceURL:self.url];
    return YES;
  }
  
  return NO;
}

- (void) createNoteFromContents:(id)contents
                          title:(NSString *)title
                       mimeType:(NSString *)mimeType
                      sourceURL:(NSURL *)url
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    ENWebContentTransformer *transformer = [[ENWebContentTransformer alloc] init];
    transformer.title = title;
    transformer.baseURL = url;
    transformer.mimeType = mimeType;
    
    ENNote *note = [transformer transformedValue:contents];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self completeWithNote:note];
    });
  });
}

@end
