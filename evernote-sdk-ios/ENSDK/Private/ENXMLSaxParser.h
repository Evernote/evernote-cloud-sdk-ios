/*
 * Copyright (c) 2009-2014 by Evernote Corporation, All rights reserved.
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

typedef struct _xmlParserCtxt xmlParserCtxt;
typedef xmlParserCtxt *xmlParserCtxtPtr;

extern NSString * const ENXMLSaxParserErrorDomain;

enum {
  ENXMLSaxParserLibXMLError = 1000,
  ENXMLSaxParserLibXMLFatalError = 1001,
  ENXMLSaxParserConnectionError = 1002,
};

@protocol ENXMLSaxParserDelegate;

@interface ENXMLSaxParser : NSObject {
  id<ENXMLSaxParserDelegate> __weak _delegate;
  xmlParserCtxtPtr _parserContext;
  BOOL _parserHalted;
  BOOL _isHTML;
  NSURLConnection *_urlConnection;
  
  NSArray *_dtds;
}

@property (weak, nonatomic) id<ENXMLSaxParserDelegate> delegate;
@property (assign, nonatomic) BOOL isHTML;

- (BOOL) parseContentsOfURLWithRequest:(NSURLRequest *)request;
- (BOOL) parseContentsOfURL:(NSURL *)url;
- (BOOL) parseContentsOfFile:(NSString *)file;
- (BOOL) parseContents:(NSString *)contents;
- (BOOL) parseData:(NSData *)data;
- (void) appendData:(NSData *)data;
- (void) finalizeParser;
- (void) stopParser;

@end

@protocol ENXMLSaxParserDelegate <NSObject>
@optional
- (void) parserDidStartDocument:(ENXMLSaxParser *)parser;
- (void) parserDidEndDocument:(ENXMLSaxParser *)parser;
- (void) parser:(ENXMLSaxParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attrDict;
- (void) parser:(ENXMLSaxParser *)parser didEndElement:(NSString *)elementName;
- (void) parser:(ENXMLSaxParser *)parser foundCharacters:(NSString *)characters;
- (void) parser:(ENXMLSaxParser *)parser foundCDATA:(NSString *)CDATABlock;
- (void) parser:(ENXMLSaxParser *)parser foundComment:(NSString *)comment;
- (void) parser:(ENXMLSaxParser *)parser didFailWithError:(NSError *)error;
@end

