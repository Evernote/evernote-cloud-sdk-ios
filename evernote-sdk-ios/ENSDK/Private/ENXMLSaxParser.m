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

#import "ENXMLSaxParser.h"
#import "ENSDKPrivate.h"
#import "ENXMLDTD.h"
#import "ENXMLUtils.h"

#include <libxml/HTMLtree.h>
#include <unistd.h>

NSString * const ENXMLSaxParserErrorDomain = @"ENXMLSaxParserErrorDomain";

@interface ENXMLDTD ()
- (xmlEntityPtr) xmlEntityNamed:(NSString *)name;
- (xmlElementPtr) xmlElementNamed:(NSString *)name;
@end

@interface ENXMLSaxParser()
- (xmlEntityPtr) lookupEntity: (const xmlChar *) name;
@end

@implementation ENXMLSaxParser

static void fatalErrorCallback(void *ctx, const char *msg, ...) { 
  va_list args;
  va_start(args, msg);
  NSString *message = [NSString stringWithCString:msg encoding:NSUTF8StringEncoding];
  NSString *errorMessage = [[NSString alloc] initWithFormat:message arguments:args];
  va_end(args);
  ENSDKLogError(@"ENXMLSaxParser: fatal error %@", errorMessage);

  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  id<ENXMLSaxParserDelegate> delegate = parser->_delegate;
  if (delegate != nil && [delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
    NSError *error = [NSError errorWithDomain:ENXMLSaxParserErrorDomain 
                                         code:ENXMLSaxParserLibXMLFatalError 
                                     userInfo:[NSDictionary dictionaryWithObject:errorMessage
                                                                          forKey:@"message"]];
    [delegate parser:parser didFailWithError:error];
  }
}
static void errorCallback(void *ctx, const char *msg, ...) {
  va_list args;
  va_start(args, msg);
  NSString *message = [NSString stringWithCString:msg encoding:NSUTF8StringEncoding];
  NSString *errorMessage = [[NSString alloc] initWithFormat:message arguments:args];
  va_end(args);
  ENSDKLogInfo(@"ENXMLSaxParser: %@ (nonfatal)", errorMessage);
#if 0
  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  id<ENXMLSaxParserDelegate> delegate = parser->_delegate;
  if (delegate != nil && [delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
    NSError *error = [NSError errorWithDomain:ENXMLSaxParserErrorDomain 
                                         code:ENXMLSaxParserLibXMLError 
                                     userInfo:[NSDictionary dictionaryWithObject:errorMessage
                                                                          forKey:@"message"]];
    [delegate parser:parser didFailWithError:error];
  }
#endif
}

/**
 * SAX parser callbacks.  
 */
static void startDocumentSAXCallback(void *ctx) {
  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  [parser->_delegate parserDidStartDocument:parser];
}

static void endDocumentSAXCallback(void *ctx) {
  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  [parser->_delegate parserDidEndDocument:parser];
}


static void startElementSAXCallback(void * ctx,
                             const xmlChar * name,
                             const xmlChar ** attrs)
{
  NSString *elementName = NSStringFromXmlChar(name);
  NSMutableDictionary * attrDict = [[NSMutableDictionary alloc] init];
  if (attrs != NULL) {
    while (*attrs != NULL) {
      NSString * keyStr = NSStringFromXmlChar(*attrs);
      attrs++;
      
      id value = NSStringFromXmlChar(*attrs);
      attrs++;
      
      if (value == nil) {
        value = [NSNull null];
      }
      
      if (keyStr != nil)
        [attrDict setObject: value forKey: [keyStr lowercaseString]];
      
    }
  }  
  
  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  [parser->_delegate parser:parser 
            didStartElement:elementName 
                 attributes:attrDict];
}

static void endElementSAXCallback(void * ctx,
                           const xmlChar * name)
{
  ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
  NSString *elementName = NSStringFromXmlChar(name);
  [parser->_delegate parser:parser didEndElement:elementName];
}

static void charactersSAXCallback(void * ctx, 
                           const xmlChar * ch, 
                           int len) 
{
  NSString *characters = NSStringFromXmlCharWithLength(ch, len);
  if (characters != nil) {
    ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
    [parser->_delegate parser:parser foundCharacters:characters];
  }
}

static void cdataBlockSAXCallback(void * ctx, 
                           const xmlChar * value, 
                           int len)
{
  NSString *cdata = NSStringFromXmlCharWithLength(value, len);
  if (cdata != nil) {
    ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
    [parser->_delegate parser:parser foundCDATA:cdata];
  }
}

static void commentBlockSAXCallback(void *ctx,
                             const xmlChar *value) 
{
  NSString *comment = NSStringFromXmlChar(value);
  if (comment != nil) {
    ENXMLSaxParser *parser = (__bridge ENXMLSaxParser *)ctx;
    [parser->_delegate parser:parser foundComment:comment];
  }
}

static xmlEntityPtr getEntitySAXCallback (void * ctx, 
                                   const xmlChar * name)
{
  xmlEntityPtr result = xmlGetPredefinedEntity(name);
  if (result) {
    return result;
  }

  result = [(__bridge ENXMLSaxParser *)ctx lookupEntity:name];
  if (result) {
    return result;
  }

  ENSDKLogInfo(@"Ignoring unknown entity '%s'", name);
  return NULL;
}


@synthesize delegate = _delegate;
@synthesize isHTML = _isHTML;

- (id) init {
  self = [super init];
  if (self != nil) {
    _dtds = [[NSArray alloc] initWithObjects:
             [ENXMLDTD lat1DTD],
             [ENXMLDTD symbolDTD],
             [ENXMLDTD specialDTD],
             nil];
  }
  return self;
}

- (void) dealloc {
  _delegate = nil;
  [self stopParser];
  
  _dtds = nil;
}

- (xmlEntityPtr) lookupEntity: (const xmlChar *) name {
  NSString *elementName = NSStringFromXmlChar(name);
  xmlEntityPtr result = NULL;
  for (ENXMLDTD *aDTD in _dtds) {
    result = [aDTD xmlEntityNamed:elementName];
    if (result != NULL) {
      break;
    }
  }
  return result;
}

- (xmlSAXHandler) saxHandler {
  xmlSAXHandler saxxy;
  memset(&saxxy, 0, sizeof(xmlSAXHandler));
  id<ENXMLSaxParserDelegate> delegate = _delegate;
  if (delegate != nil) {
    if ([delegate respondsToSelector:@selector(parser:foundComment:)] == YES) {
      saxxy.comment = &commentBlockSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parser:foundCharacters:)] == YES) {
      saxxy.characters = &charactersSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parserDidStartDocument:)] == YES) {
      saxxy.startDocument = &startDocumentSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parserDidEndDocument:)] == YES) {
      saxxy.endDocument = &endDocumentSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parser:didStartElement:attributes:)] == YES) {
      saxxy.startElement = &startElementSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parser:didEndElement:)] == YES) {
      saxxy.endElement = &endElementSAXCallback;
    }
    if ([delegate respondsToSelector:@selector(parser:foundCDATA:)] == YES) {
      saxxy.cdataBlock = &cdataBlockSAXCallback;
    }
  }
  saxxy.getEntity = &getEntitySAXCallback;
  saxxy.fatalError = &fatalErrorCallback;
  saxxy.error = &errorCallback;
  return saxxy;
}

#pragma mark -
#pragma mark 
- (void) appendBytes:(char *)bytes length:(int)length {
  if (_parserContext == NULL) {
    xmlSAXHandler saxxy = [self saxHandler];
    if (_isHTML == YES) {
      _parserContext = htmlCreatePushParserCtxt(&saxxy, 
                                                (__bridge void *)(self), 
                                                bytes, 
                                                length, 
                                                NULL, 
                                                XML_CHAR_ENCODING_UTF8);    
    }
    else {
      _parserContext = xmlCreatePushParserCtxt(&saxxy,
                                               (__bridge void *)(self), 
                                               bytes, 
                                               length, 
                                               NULL);
      xmlCtxtUseOptions(_parserContext, XML_PARSE_RECOVER);
    }
  }
  else {
    if (_isHTML == YES) {
      htmlParseChunk(_parserContext, 
                     bytes, 
                     length, 
                     false);
    }
    else {
      xmlParseChunk(_parserContext, 
                    bytes, 
                    length, 
                    false);
    }
  }
}

- (void) appendData:(NSData *)data {
  [self appendBytes:(char *)[data bytes]
             length:(int)[data length]];
}


- (void) finalizeParser {
  if (_parserContext != NULL) {
    if (_isHTML == YES) {
      htmlParseChunk(_parserContext, 
                     NULL, 
                     0, 
                     true);
    }
    else {
      xmlParseChunk(_parserContext, 
                    NULL, 
                    0, 
                    true);
    }
    xmlFreeParserCtxt(_parserContext);
    _parserContext = NULL;
    _parserHalted = YES;
  }
}

- (BOOL) parseContentsOfFile:(NSString *)file {
  if (self.delegate == nil) {
    return NO;
  }
  NSError *attrError = nil;
  NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:&attrError];
  if (fileAttributes == nil) {
    ENSDKLogError(@"attributesOfItemAtPath:%@ returned error:%@", file, attrError);
    return NO;
  }
  if ([fileAttributes fileSize] == 0) {
    ENSDKLogError(@"The file %@ is 0 bytes!", file);
    return NO;
  }
  
  [self stopParser];
  
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:file];
  if (inputStream == nil) {
    return NO;
  }
  [inputStream open];

  _parserHalted = NO;
  int pagesize = getpagesize();
  uint8_t *readBuffer = calloc(pagesize, 1);
  
  while(_parserHalted == NO) {
    int amountRead = (int)[inputStream read:readBuffer
                             maxLength:pagesize];
    
    if (amountRead < 0) {
      ENSDKLogInfo(@"read:maxLength: returned: %i", amountRead);
      _parserHalted = YES;
    }
    else if (amountRead == 0) {
      _parserHalted = YES;
    }
    else {
      [self appendBytes:(char *)readBuffer 
                 length:amountRead];
    }
  }
  free(readBuffer);
  
  [self finalizeParser];
  [inputStream close];
  return YES;
}

- (BOOL) parseData:(NSData *)data {
  [self stopParser];
  [self appendData:data];
  [self finalizeParser];
  return YES;
}

- (BOOL) parseContents:(NSString *)contents {
  [self stopParser];
  [self appendData:[contents dataUsingEncoding:NSUTF8StringEncoding]];
  [self finalizeParser];
  return YES;
}

- (BOOL) parseContentsOfURLWithRequest:(NSURLRequest *)request {
  if (self.delegate == nil || request == nil) {
    return NO;
  }
  
  [self stopParser];
  _parserHalted = NO;
  
  @autoreleasepool {
    _urlConnection = [[NSURLConnection alloc] initWithRequest:request
                                                     delegate:self];
    
    if (_urlConnection == nil) {
      return NO;
    }
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [_urlConnection scheduleInRunLoop:runLoop
                              forMode:NSDefaultRunLoopMode];
    
    [_urlConnection start];
    while (_parserHalted == NO && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self finalizeParser];
    [_urlConnection cancel];
    [_urlConnection unscheduleFromRunLoop:runLoop
                                  forMode:NSDefaultRunLoopMode];
    _urlConnection = nil;
  }  
  return YES;
}

- (BOOL) parseContentsOfURL:(NSURL *)url {
  if ([url isFileURL] == YES) {
    return [self parseContentsOfFile:[url path]];
  }
  return [self parseContentsOfURLWithRequest:[NSURLRequest requestWithURL:url]];
}


- (void) stopParser {
  if (_urlConnection != nil) {
    [_urlConnection cancel];
    _urlConnection = nil;
  }
  if (_parserContext != NULL) {
    xmlStopParser(_parserContext);
  }
  _parserHalted = YES;
}

#pragma mark -
#pragma mark 
- (void) _stopAndSendError:(NSError *)error {
  id<ENXMLSaxParserDelegate> strongDelegate = _delegate;
  if (strongDelegate != nil && [strongDelegate respondsToSelector:@selector(parser:didFailWithError:)]) {
    [strongDelegate parser:self didFailWithError:error];
  }
  [self stopParser];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [self finalizeParser];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [self _stopAndSendError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if ([response isKindOfClass:[NSHTTPURLResponse class]] == YES && [(NSHTTPURLResponse *)response statusCode] != 200) {
    NSDictionary *userInfo = nil;
    if (response != nil) {
      userInfo = [NSDictionary dictionaryWithObject:response forKey:@"response"];
    }
    NSError *error = [NSError errorWithDomain:ENXMLSaxParserErrorDomain 
                                         code:ENXMLSaxParserConnectionError 
                                     userInfo:userInfo];
    [self _stopAndSendError:error];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self appendData:data];
}

@end
