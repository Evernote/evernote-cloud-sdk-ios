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

#import <Foundation/Foundation.h>

@protocol ENTProtocol;

@interface ENTException : NSException 

+ (id) exceptionWithName:(NSString *) name;

+ (id) exceptionWithName:(NSString *) name
                  reason:(NSString *) reason;

+ (id) exceptionWithName:(NSString *) name
                  reason:(NSString *) reason
                   error:(NSError *) error;

@end

enum {
  ENTApplicationException_UNKNOWN = 0,
  ENTApplicationException_UNKNOWN_METHOD = 1,
  ENTApplicationException_INVALID_MESSAGE_TYPE = 2,
  ENTApplicationException_WRONG_METHOD_NAME = 3,
  ENTApplicationException_BAD_SEQUENCE_ID = 4,
  ENTApplicationException_MISSING_RESULT = 5,
  ENTApplicationException_INTERNAL_ERROR = 6,
  ENTApplicationException_PROTOCOL_ERROR = 7
};

@interface ENTApplicationException : ENTException

+ (ENTApplicationException *) read: (id <ENTProtocol>) protocol;

- (void) write: (id <ENTProtocol>) protocol;

+ (ENTApplicationException *) exceptionWithType: (int) type
                                       reason: (NSString *) message;

@end
