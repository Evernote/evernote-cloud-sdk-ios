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

#import "ENWebContentTransformer.h"
#import "ENSDKPrivate.h"
#import "ENMLConstants.h"

#import "ENMIMEUtils.h"
#import "ENMLWriter.h"
#import "ENXMLSaxParser.h"

#import "NSData+EvernoteSDK.h"

#import "ENWebArchive.h"

@interface ENWebContentTransformer()<ENXMLSaxParserDelegate>

@property (strong, nonatomic) ENXMLSaxParser *htmlParser;
@property (strong, nonatomic) ENMLWriter *enmlWriter;
@property (strong, nonatomic) ENXMLDTD *enmlDTD;
@property (strong, nonatomic) NSURL *archiveBaseURL;

@property (strong, nonatomic) ENWebArchive *webArchive;
@property (strong, nonatomic) ENNote *note;

@property (strong, nonatomic) NSArray *ignorableTags;
@property (strong, nonatomic) NSArray *ignorableAttributes;
@property (strong, nonatomic) NSArray *skipTags;
@property (strong, nonatomic) NSArray *inlineElements;

@property (nonatomic) NSUInteger ignoreElementCount;
@property (nonatomic) BOOL inTitleElement;

@end

@implementation ENWebContentTransformer

+ (BOOL)allowsReverseTransformation {
  return NO;
}

+ (Class)transformedValueClass {
  return [ENNote class];
}

- (id) init {
  self = [super init];
  if (self != nil) {
    self.skipTags = @[@"html", @"head", @"body",];
    self.ignorableTags = @[@"script", @"style", @"meta", @"title",];
    self.ignorableAttributes = @[ @"class" ];
    self.inlineElements = @[@"object",@"button",@"input",@"label",@"select",@"textarea",];
  }
  return self;
}

- (id)transformedValue:(id)value {
  ENNote *note = [[ENNote alloc] init];
  self.note = note;

  ENMLWriter *enmlWriter = [[ENMLWriter alloc] init];
  [enmlWriter startDocument];
  self.enmlWriter = enmlWriter;
  
  self.enmlDTD = [ENXMLDTD enml2dtd];

  if ([value isKindOfClass:[ENWebArchive class]] == YES || [value isKindOfClass:[NSString class]] == YES) {
    ENXMLSaxParser *parser = [[ENXMLSaxParser alloc] init];
    parser.isHTML = YES;
    parser.delegate = self;
    
    NSString *html = nil;
    if ([value isKindOfClass:[ENWebArchive class]] == YES) {
      ENWebArchive *webArchive = (ENWebArchive *)value;
      html = [self htmlFromWebArchive:webArchive];
      self.baseURL = webArchive.mainResource.URL;
      self.webArchive = webArchive;
    }
    else {
      html = (NSString *)value;
    }

    self.archiveBaseURL = [self archiveBaseURLFromURL:self.baseURL];
    [parser parseContents:html];
  }
  else if ([value isKindOfClass:[NSData class]] == YES) {
    ENResource *resource = [[ENResource alloc] init];
    resource.sourceUrl = [self.baseURL absoluteString];
    resource.filename = [self filenameFromURL:self.baseURL];
    resource.data = value;
    
    NSString *mimeType = self.mimeType;
    if (mimeType == nil) {
      mimeType = [self mimeTypeFromFilename:resource.filename];
    }
    resource.mimeType = mimeType;

    [self.note addResource:resource];

    [enmlWriter writeResourceWithDataHash:resource.dataHash
                                     mime:resource.mimeType
                               attributes:nil];
  }
  else {
    return nil;
  }

  [enmlWriter endDocument];
  note.content = [[ENNoteContent alloc] initWithENML:enmlWriter.contents];
  note.sourceUrl = [self.baseURL absoluteString];
  
  NSString *title = self.title;
  if (title == nil) {
    title = note.sourceUrl;
  }
  if (title == nil) {
    title = ENSDKLocalizedString(@"Untitled", @"Untitled");
  }
  note.title = title;
  
  return note;
}

#pragma mark -
#pragma mark
- (NSString *) htmlFromWebArchive:(ENWebArchive *)webArchive {
  ENWebResource *mainResource = webArchive.mainResource;
  NSString *textEncodingName = mainResource.textEncodingName;
  if (textEncodingName == nil) {
    textEncodingName = @"UTF-8";
  }
  
  CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
  NSStringEncoding stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
  NSData *data = mainResource.data;
  if (!data) {
    return nil;
  }
    
  NSString *html = [[NSString alloc] initWithData:data
                                         encoding:stringEncoding];
  return html;
}

- (NSURL *) archiveBaseURLFromURL:(NSURL *)url {
  if (url == nil) {
    return nil;
  }
  
  NSURL *archiveBaseURL = nil;
  NSString * lastPathComponent = (__bridge_transfer NSString *) CFURLCopyLastPathComponent((__bridge CFURLRef) url);
  if ([@"file" isEqualToString:[url scheme]] == YES && [@"/" isEqualToString:lastPathComponent] == YES) {
    archiveBaseURL = url;
  }
  else if ([lastPathComponent length] == 0) {
    // e.g. http://www.evernote.com
    archiveBaseURL = url;
  }
  else if (CFURLHasDirectoryPath((__bridge CFURLRef) url) == YES) {
    // e.g. http://worrydream.com/MagicInk/
    archiveBaseURL = url;
  }
  else {
    // e.g. http://www.evernote.com/index.html
    // e.g. http://www.evernote.com/blahdeblah
    // lop off the last component
    archiveBaseURL = (__bridge_transfer NSURL *) CFURLCreateCopyDeletingLastPathComponent(NULL, (__bridge CFURLRef) url);
  }
  return archiveBaseURL;
}

- (NSURL *) sanitizeURLAttribute:(NSString *)urlAttribute {
  if (urlAttribute == nil) {
    return nil;
  }
  
  NSString *preprocessedString = [urlAttribute stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *urlString = [preprocessedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSURL *absoluteURL = [NSURL URLWithString:urlString relativeToURL:self.baseURL];
  if ([ENMLWriter validateURLComponents:absoluteURL] == NO) {
    NSArray *subresources = [self.webArchive subresources];
    NSURL *url = [NSURL URLWithString:urlAttribute];
    for (ENWebResource *aResource in subresources) {
      if ([[aResource URL] isEqual:url] == YES) {
        return url;
      }
    }
    return nil;
  }
  
  return absoluteURL;
}

- (NSString *) filenameFromURL:(NSURL *)url {
  if (CFURLHasDirectoryPath((CFURLRef)url) == NO) {
    return [url lastPathComponent];
  }
  return nil;
}

- (NSString *) mimeTypeFromFilename:(NSString *)filename {
  NSString *mimeType = nil;
  if (filename != nil) {
    mimeType = [ENMIMEUtils determineMIMETypeForFile:filename];
  }
  if (mimeType == nil) {
    mimeType = ENMIMETypeOctetStream;
  }
  return mimeType;
}

- (ENResource *) resourceFromWebResource:(ENWebResource *)webResource {
  NSData *rsrcData = webResource.data;
  if (rsrcData == nil || [rsrcData length] == 0) {
    return nil;
  }
  
  ENResource *resource = [[ENResource alloc] init];
  NSURL *resourceUrl = webResource.URL;
  resource.sourceUrl = [resourceUrl absoluteString];
  resource.filename = [self filenameFromURL:resourceUrl];
  resource.data = rsrcData;
  
  NSString *mimeType = webResource.MIMEType;
  if (mimeType == nil || [mimeType length] == 0) {
    mimeType = [self mimeTypeFromFilename:resource.filename];
  }
  resource.mimeType = mimeType;

  return resource;
}

#pragma mark -
#pragma mark ENXMLSaxParser delegates
- (void) parser:(ENXMLSaxParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attrDict {
  if (self.baseURL == nil && [elementName isEqualToString:@"base"]) {
    NSString *href = [attrDict objectForKey:@"href"];
    if (href != nil) {
      self.baseURL = [NSURL URLWithString:href];
    }
  }
  
  if (self.title == nil && [elementName isEqualToString:@"title"]) {
    self.inTitleElement = YES;
    self.title = @"";
    return;
  }
  
  if (self.ignoreElementCount > 0) {
    self.ignoreElementCount++;
    return;
  }

  if ([self.skipTags containsObject:elementName] == YES) {
    return;
  }
  
  if ([self.ignorableTags containsObject:elementName] == YES) {
    self.ignoreElementCount = 1;
    return;
  }

  NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attrDict];
  for (NSString *anAttribute in attrDict) {
    if ([self.ignorableAttributes containsObject:anAttribute] == YES) {
      [newAttributes removeObjectForKey:anAttribute];
    }
  }
  
  NSString *tagName = elementName;
  if ([tagName isEqualToString:@"img"] == YES) {
    NSString *imgSrc = newAttributes[@"src"];
    NSURL *sanitizedURL = [self sanitizeURLAttribute:imgSrc];
    if (sanitizedURL == nil) {
      self.ignoreElementCount = 1;
      return;
    }

    for (ENWebResource *aResource in self.webArchive.subresources) {
      if ([[[aResource URL] absoluteString] isEqualToString:[sanitizedURL absoluteString]] == YES) {
        ENResource *resource = [self resourceFromWebResource:aResource];
        if (resource != nil) {
          [self.note addResource:resource];
          
          [newAttributes removeObjectForKey:@"src"];
          [self.enmlWriter writeResourceWithDataHash:resource.dataHash
                                                mime:resource.mimeType
                                          attributes:newAttributes];

          self.ignoreElementCount = 1;
          return;
        }
      }
    }
    
    newAttributes[@"src"] = [sanitizedURL absoluteString];
  }
  else if ([tagName isEqualToString:@"a"] == YES) {
    NSString *href = [attrDict objectForKey:@"href"];
    if (href != nil) {
      NSURL *sanitizedURL = [self sanitizeURLAttribute:href];
      
      if (sanitizedURL == nil) {
        [newAttributes removeObjectForKey:@"href"];
      }
      else {
        newAttributes[@"href"] = [sanitizedURL absoluteString];
      }
    }
  }
  else if ([self.enmlDTD isElementLegal:tagName] == NO) {
    if ([self.inlineElements containsObject:tagName]) {
      tagName = @"span";
    }
    else {
      tagName = @"div";
    }
  }

  [self.enmlWriter startElement:tagName
                 withAttributes:newAttributes];
}

- (void) parser:(ENXMLSaxParser *)parser didEndElement:(NSString *)elementName {
  if (self.inTitleElement == YES && [elementName isEqualToString:@"title"] == YES) {
    self.inTitleElement = NO;
    return;
  }
  
  if (self.ignoreElementCount > 0) {
    self.ignoreElementCount--;
    return;
  }
  
  if ([self.skipTags containsObject:elementName] == YES) {
    return;
  }
  
  [self.enmlWriter endElement];
}

- (void) parser:(ENXMLSaxParser *)parser foundCharacters:(NSString *)characters {
  if (self.inTitleElement == YES) {
    self.title = [self.title stringByAppendingString:characters];
//    self.inTitleElement = NO;
    return;
  }
  
  if (self.ignoreElementCount > 0) {
    return;
  }
  
  [self.enmlWriter writeString:characters];
}

- (void) parser:(ENXMLSaxParser *)parser didFailWithError:(NSError *)error {
  NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

@end
