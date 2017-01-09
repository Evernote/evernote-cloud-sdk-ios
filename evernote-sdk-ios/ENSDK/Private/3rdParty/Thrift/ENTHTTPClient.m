/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "ENTHTTPClient.h"

@interface ENTHTTPClient()

@property (strong, nonatomic) NSMutableData *requestData;
@property (strong, nonatomic) NSData *responseData;
@property (assign, nonatomic) int responseDataOffset;
@property (strong, nonatomic) NSString *userAgent;
@property (assign, nonatomic) int timeout;


@end

@implementation ENTHTTPClient

- (id) initWithURL: (NSURL *) aURL {
  return [self initWithURL: aURL
                 userAgent: nil
                   timeout: 0];
}

- (id) initWithURL: (NSURL *) aURL
         userAgent: (NSString *) userAgent
           timeout: (int) timeout
{
  self = [super init];
  if (self != nil) {
    self.timeout = timeout;
    self.url = aURL;
    self.userAgent = userAgent;
    
    // create our request data buffer
    self.requestData = [[NSMutableData alloc] initWithCapacity: 1024];
  }
  return self;
}

- (int) readAll: (uint8_t *) buf offset: (int) off length: (int) len {
  NSRange r;
  r.location = self.responseDataOffset;
  r.length = len;

  [self.responseData getBytes: buf+off range: r];
  self.responseDataOffset += len;

  return len;
}

- (void) write: (const uint8_t *) data offset: (unsigned int) offset length: (unsigned int) length {
  [self.requestData appendBytes: data+offset length: length];
}

- (NSMutableURLRequest *) newRequest {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: self.url];
  [request setHTTPMethod: @"POST"];
  [request setValue: @"application/x-thrift" forHTTPHeaderField: @"Content-Type"];
  [request setValue: @"application/x-thrift" forHTTPHeaderField: @"Accept"];
  
  NSString * userAgent = self.userAgent;
  if (userAgent == nil) {
    userAgent = @"Cocoa/THTTPClient";
  }
  [request setValue: userAgent forHTTPHeaderField: @"User-Agent"];
  
  [request setCachePolicy: NSURLRequestReloadIgnoringCacheData];
  if (self.timeout != 0) {
    [request setTimeoutInterval: self.timeout];
  }
  
  return request;
}

- (void) flush {
  // make the HTTP request
  NSMutableURLRequest *request = [self newRequest];
  [request setHTTPBody: self.requestData]; // not sure if it copies the data

  NSURLResponse * response;
  NSError * error;
  NSData * responseData = [NSURLConnection sendSynchronousRequest: request
                                                returningResponse: &response
                                                            error: &error];

  [self.requestData setLength: 0];

  if (responseData == nil) {
    @throw [ENTTransportException exceptionWithName: @"TTransportException"
                                reason: @"Could not make HTTP request"
                                error: error];
  }
  if (![response isKindOfClass: [NSHTTPURLResponse class]]) {
    @throw [ENTTransportException exceptionWithName: @"TTransportException"
                                           reason: [NSString stringWithFormat: @"Unexpected NSURLResponse type: %@",
                                                    NSStringFromClass([response class])]];
  }

  NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
  if ([httpResponse statusCode] != 200) {
    @throw [ENTTransportException exceptionWithName: @"TTransportException"
                                           reason: [NSString stringWithFormat: @"Bad response from HTTP server: %ld",
                                                    (long)[httpResponse statusCode]]];
  }

  self.responseData = responseData;
  self.responseDataOffset = 0;
}

- (void)cancel {
    // noop
}

@end
