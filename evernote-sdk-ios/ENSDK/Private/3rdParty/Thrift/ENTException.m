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

#import "ENTException.h"
#import "ENTProtocol.h"

@implementation ENTException

+ (id) exceptionWithName: (NSString *) name {
  return [self exceptionWithName: name reason: @"unknown" error: nil];
}


+ (id) exceptionWithName: (NSString *) name
                  reason: (NSString *) reason
{
  return [self exceptionWithName: name reason: reason error: nil];
}


+ (id) exceptionWithName: (NSString *) name
                  reason: (NSString *) reason
                   error: (NSError *) error
{
  NSDictionary * userInfo = nil;
  if (error != nil) {
    userInfo = [NSDictionary dictionaryWithObject: error forKey: @"error"];
  }

  return [super exceptionWithName: name
                reason: reason
                userInfo: userInfo];
}

- (NSString *) description {
  NSMutableString * result = [NSMutableString stringWithString: [self name]];
  [result appendFormat: @": %@", [self reason]];
  if ([self userInfo] != nil) {
    [result appendFormat: @"\n  userInfo = %@", [self userInfo]];
  }

  return result;
}

@end

@implementation ENTApplicationException {
  int _type;
}

- (id) initWithType: (int) type
             reason: (NSString *) reason
{
  _type = type;
  
  NSString * name;
  switch (type) {
    case ENTApplicationException_UNKNOWN_METHOD:
      name = @"Unknown method";
      break;
    case ENTApplicationException_INVALID_MESSAGE_TYPE:
      name = @"Invalid message type";
      break;
    case ENTApplicationException_WRONG_METHOD_NAME:
      name = @"Wrong method name";
      break;
    case ENTApplicationException_BAD_SEQUENCE_ID:
      name = @"Bad sequence ID";
      break;
    case ENTApplicationException_MISSING_RESULT:
      name = @"Missing result";
      break;
    default:
      name = @"Unknown";
      break;
  }
  
  self = [super initWithName: name reason: reason userInfo: nil];
  return self;
}


+ (ENTApplicationException *) read: (id <ENTProtocol>) protocol {
  NSString * reason = nil;
  int type = ENTApplicationException_UNKNOWN;
  int fieldType;
  int fieldID;
  
  [protocol readStructBeginReturningName: NULL];
  
  while (true) {
    [protocol readFieldBeginReturningName: NULL
                                     type: &fieldType
                                  fieldID: &fieldID];
    if (fieldType == TType_STOP) {
      break;
    }
    switch (fieldID) {
      case 1:
        if (fieldType == TType_STRING) {
          reason = [protocol readString];
        } else {
          [ENTProtocolUtil skipType: fieldType onProtocol: protocol];
        }
        break;
      case 2:
        if (fieldType == TType_I32) {
          type = [protocol readI32];
        } else {
          [ENTProtocolUtil skipType: fieldType onProtocol: protocol];
        }
        break;
      default:
        [ENTProtocolUtil skipType: fieldType onProtocol: protocol];
        break;
    }
    [protocol readFieldEnd];
  }
  [protocol readStructEnd];
  
  return [ENTApplicationException exceptionWithType: type reason: reason];
}

- (void) write: (id <ENTProtocol>) protocol {
  [protocol writeStructBeginWithName: @"TApplicationException"];
  
  if ([self reason] != nil) {
    [protocol writeFieldBeginWithName: @"message"
                                 type: TType_STRING
                              fieldID: 1];
    [protocol writeString: [self reason]];
    [protocol writeFieldEnd];
  }
  
  [protocol writeFieldBeginWithName: @"type"
                               type: TType_I32
                            fieldID: 2];
  [protocol writeI32: _type];
  [protocol writeFieldEnd];
  
  [protocol writeFieldStop];
  [protocol writeStructEnd];
}


+ (ENTApplicationException *) exceptionWithType: (int) type
                                       reason: (NSString *) reason
{
  return [[ENTApplicationException alloc] initWithType: type
                                              reason: reason];
}

@end
