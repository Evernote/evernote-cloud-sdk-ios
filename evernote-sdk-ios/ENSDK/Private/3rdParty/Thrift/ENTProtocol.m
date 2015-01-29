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

#import "ENTProtocol.h"

#import "FATField.h"
#import "FATObject.h"
#import "ENTTransport.h"

@implementation ENTProtocolException
@end

@implementation ENTProtocolUtil

+ (void) skipType: (int) type onProtocol: (id <ENTProtocol>) protocol {
  switch (type) {
    case TType_BOOL:
      [protocol readBool];
      break;
    case TType_BYTE:
      [protocol readByte];
      break;
    case TType_I16:
      [protocol readI16];
      break;
    case TType_I32:
      [protocol readI32];
      break;
    case TType_I64:
      [protocol readI64];
      break;
    case TType_DOUBLE:
      [protocol readDouble];
      break;
    case TType_STRING:
      [protocol readString];
      break;
    case TType_STRUCT:
      [protocol readStructBeginReturningName: NULL];
      while (true) {
        int fieldType;
        [protocol readFieldBeginReturningName: nil type: &fieldType fieldID: nil];
        if (fieldType == TType_STOP) {
          break;
        }
        [self skipType: fieldType onProtocol: protocol];
        [protocol readFieldEnd];
      }
      [protocol readStructEnd];
      break;
    case TType_MAP: {
      int keyType;
      int valueType;
      int size;
      [protocol readMapBeginReturningKeyType: &keyType valueType: &valueType size: &size];
      int i;
      for (i = 0; i < size; i++) {
        [self skipType: keyType onProtocol: protocol];
        [self skipType: valueType onProtocol: protocol];
      }
      [protocol readMapEnd];
      break;
    }
    case TType_SET: {
      int elemType;
      int size;
      [protocol readSetBeginReturningElementType: &elemType size: &size];
      int i;
      for (i = 0; i < size; i++) {
        [self skipType: elemType onProtocol: protocol];
      }
      [protocol readSetEnd];
      break;
    }
    case TType_LIST: {
      int elemType;
      int size;
      [protocol readListBeginReturningElementType: &elemType size: &size];
      int i;
      for (i = 0; i < size; i++) {
        [self skipType: elemType onProtocol: protocol];
      }
      [protocol readListEnd];
      break;
    }
    default:
      return;
  }
}

+ (id) _readValueForField:(FATField *)field
             fromProtocol:(id<ENTProtocol>)inProtocol
{
  id fieldValue = nil;
  switch (field.type) {
    case TType_BOOL:
      fieldValue = [NSNumber numberWithBool: [inProtocol readBool]];
      break;
    case TType_BYTE:
      fieldValue = [NSNumber numberWithInt: [inProtocol readByte]];
      break;
    case TType_DOUBLE:
      fieldValue = [NSNumber numberWithDouble: [inProtocol readDouble]];
      break;
    case TType_I16:
      fieldValue = [NSNumber numberWithShort: [inProtocol readI16]];
      break;
    case TType_I32:
      fieldValue = [NSNumber numberWithInt: [inProtocol readI32]];
      break;
    case TType_I64:
      fieldValue = [NSNumber numberWithLongLong: [inProtocol readI64]];
      break;
    case TType_STRING:
      fieldValue = [inProtocol readString];
      break;
    case TType_BINARY:
      fieldValue = [inProtocol readBinary];
      break;
    case TType_STRUCT:
      fieldValue = [[field.valueClass alloc] init];
      [self readFromProtocol:inProtocol
                  ontoObject:fieldValue];
      break;
    case TType_MAP: {
      int mapSize = 0;
      int mapKeyType = 0;
      int mapValueType = 0;
      [inProtocol readMapBeginReturningKeyType: &mapKeyType valueType: &mapValueType size: &mapSize];
      
      FATField *keyField = [[FATField alloc] init];
      keyField.type = mapKeyType;
      keyField.valueClass = field.keyClass;
      
      FATField *valueField = [[FATField alloc] init];
      valueField.type = mapValueType;
      valueField.valueClass = field.valueClass;
      
      NSMutableDictionary *mapValue = [[NSMutableDictionary alloc] initWithCapacity:mapSize];
      for (int i=0; i<mapSize; i++) {
        id entryKey = [self _readValueForField:keyField
                                fromProtocol:inProtocol];
        id entryValue = [self _readValueForField:valueField
                                    fromProtocol:inProtocol];
        
        [mapValue setObject:entryValue forKey:entryKey];
      }
      [inProtocol readMapEnd];
      fieldValue = mapValue;
      break;
    }
    case TType_SET: {
      int setSize = 0;
      int setElementType = 0;
      [inProtocol readSetBeginReturningElementType: &setElementType size: &setSize];
      
      FATField *setField = [[FATField alloc] init];
      setField.type = setElementType;
      setField.valueClass = field.valueClass;

      NSMutableSet *setValue = [[NSMutableSet alloc] initWithCapacity: setSize];
      for (int i = 0; i < setSize; i++) {
        id setElement = [self _readValueForField:setField
                                    fromProtocol:inProtocol];
        if (setElement != nil) {
          [setValue addObject: setElement];
        }
      }
      
      [inProtocol readListEnd];
      fieldValue = setValue;
      break;
    }
    case TType_LIST: {
      int listSize = 0;
      int listElementType = 0;
      [inProtocol readListBeginReturningElementType: &listElementType size: &listSize];
      
      FATField *listField = [[FATField alloc] init];
      listField.type = listElementType;
      listField.valueClass = field.valueClass;
      
      NSMutableArray *listValue = [[NSMutableArray alloc] initWithCapacity: listSize];
      for (int i = 0; i < listSize; i++) {
        id listElement = [self _readValueForField:listField
                                     fromProtocol:inProtocol];
        if (listElement != nil) {
          [listValue addObject: listElement];
        }
      }
      [inProtocol readListEnd];
      fieldValue = listValue;
      break;
    }
  }
  
  return fieldValue;
}

+ (void) readFromProtocol:(id<ENTProtocol>)inProtocol
               ontoObject:(id)object
{
  [inProtocol readStructBeginReturningName: NULL];
  
  NSArray *structFields = [[object class] structFields];
  while (true) {
    int fieldType = 0;
    int fieldID = 0;
    
    [inProtocol readFieldBeginReturningName: NULL
                                       type: &fieldType
                                    fieldID: &fieldID];
    if (fieldType == TType_STOP) {
      break;
    }
    
    FATField *field = nil;
    for (FATField *aField in structFields) {
      if (aField.index == (uint32_t)fieldID) {
        field = aField;
        break;
      }
    }

    if (field == nil || (field.type != (uint32_t)fieldType && field.type != TType_BINARY && fieldType != TType_STRING)) {
      if (field != nil) {
        NSLog(@"Skipping field:%@ due to type mismatch (received:%i)", field, fieldType);
      }

      [self skipType: fieldType onProtocol: inProtocol];
      continue;
    }
    else {
      id fieldValue = [self _readValueForField:field
                                  fromProtocol:inProtocol];
      
      [object setValue:fieldValue
                forKey:field.name];
      
    }
    
    [inProtocol readFieldEnd];
  }
  [inProtocol readStructEnd];
}

+ (void) _writeValue:(id)fieldValue
            forField:(FATField *)field
          toProtocol:(id<ENTProtocol>)outProtocol
{
  switch (field.type) {
    case TType_BOOL:
      [outProtocol writeBool: [fieldValue boolValue]];
      break;
    case TType_BYTE:
      [outProtocol writeByte: [fieldValue charValue]];
      break;
    case TType_DOUBLE:
      [outProtocol writeDouble: [fieldValue doubleValue]];
      break;
    case TType_I16:
      [outProtocol writeI16: [fieldValue shortValue]];
      break;
    case TType_I32:
      [outProtocol writeI32: [fieldValue intValue]];
      break;
    case TType_I64:
      [outProtocol writeI64: [fieldValue longLongValue]];
      break;
    case TType_BINARY:
      [outProtocol writeBinary: fieldValue];
      break;
    case TType_STRING:
      [outProtocol writeString: fieldValue];
      break;
    case TType_STRUCT:
      [self writeObject:fieldValue ontoProtocol:outProtocol];
      break;
    case TType_MAP: {
      FATField *keyField = [[FATField alloc] init];
      keyField.type = field.keyType;
      FATField *valueField = [[FATField alloc] init];
      valueField.type = field.valueType;
      
      [outProtocol writeMapBeginWithKeyType: field.keyType valueType: field.valueType size:(int)[fieldValue count]];
      
      for (id aMapKey in fieldValue) {
        [self _writeValue:aMapKey
                 forField:keyField
               toProtocol:outProtocol];
        [self _writeValue:[fieldValue objectForKey:aMapKey]
                 forField:valueField
               toProtocol:outProtocol];
      }
      [outProtocol writeMapEnd];
      break;
    }
    case TType_SET: {
      FATField *elementField = [[FATField alloc] init];
      elementField.type = field.valueType;
      
      [outProtocol writeSetBeginWithElementType: field.valueType size:(int)[fieldValue count]];
      [outProtocol writeSetEnd];
      for (id aListValue in fieldValue) {
        [self _writeValue:aListValue
                 forField:elementField
               toProtocol:outProtocol];
      }
      break;
    }
    case TType_LIST: {
      FATField *elementField = [[FATField alloc] init];
      elementField.type = field.valueType;
      
      [outProtocol writeListBeginWithElementType: field.valueType size:(int)[fieldValue count]];
      for (id aListValue in fieldValue) {
        [self _writeValue:aListValue
                 forField:elementField
               toProtocol:outProtocol];
      }
      [outProtocol writeListEnd];
      break;
    }
  }
}

+ (id) readMessage:(NSString *)message
      fromProtocol:(id<ENTProtocol>)inProtocol
 withResponseTypes:(NSArray *)responseTypes
{
  int msgType = 0;
  [inProtocol readMessageBeginReturningName: nil type: &msgType sequenceID: NULL];
  if (msgType == TMessageType_EXCEPTION) {
    ENTApplicationException * x = [ENTApplicationException read: inProtocol];
    [inProtocol readMessageEnd];
    @throw x;
  }
  
  NSMutableArray *responseObjects = [NSMutableArray array];
  [inProtocol readStructBeginReturningName: NULL];
  
  while (true) {
    NSString * fieldName = nil;
    int fieldType = 0;
    int fieldID = 0;
    
    [inProtocol readFieldBeginReturningName: &fieldName type: &fieldType fieldID: &fieldID];
    if (fieldType == TType_STOP) {
      break;
    }
    
    BOOL matched = NO;
    for (FATField *aResponseType in responseTypes) {
      if (aResponseType.index == (uint32_t)fieldID) {
        if (aResponseType.type != (uint32_t)fieldType && aResponseType.type != TType_BINARY && fieldType != TType_STRING) {
          NSLog(@"Skipping field:%@ due to type mismatch (received:%i)", aResponseType, fieldType);
        }
        else {
          id fieldValue = [self _readValueForField:aResponseType
                                      fromProtocol:inProtocol];
          if (fieldValue != nil) {
            [responseObjects addObject:fieldValue];
          }
          matched = YES;
        }
      }
    }
    
    if (matched == NO) {
      [ENTProtocolUtil skipType: fieldType onProtocol: inProtocol];
    }
  }
  
  [inProtocol readStructEnd];
  [inProtocol readMessageEnd];

  for (id anObject in responseObjects) {
    if ([anObject isKindOfClass:[NSException class]] == NO) {
      return anObject;
    }
  }
  
  for (id anObject in responseObjects) {
    if ([anObject isKindOfClass:[NSException class]] == YES) {
      @throw anObject;
    }
  }
    
  BOOL nonExceptionTypesPresent = NO;
  for (FATField *aResponseType in responseTypes) {
    if ([aResponseType.valueClass isSubclassOfClass:[FATException class]] == NO) {
      nonExceptionTypesPresent = YES;
      break;
    }
  }
    
  if (nonExceptionTypesPresent) {
    @throw [ENTApplicationException exceptionWithType: ENTApplicationException_MISSING_RESULT
                                             reason: [message stringByAppendingString:@" failed: unknown result"]];
  }
    
  return nil;
}

+ (void) writeObject:(id)object
        ontoProtocol:(id<ENTProtocol>)outProtocol
{
  [outProtocol writeStructBeginWithName: [[object class] structName]];
  
  for (FATField *aField in [[object class] structFields]) {
    NSString *fieldName = aField.name;
    id fieldValue = [object valueForKey:fieldName];
    if (fieldValue == nil) {
      continue;
    }
    
    int fieldType = aField.type;
    if (fieldType == TType_BINARY) {
      fieldType = TType_STRING;
    }
    
    [outProtocol writeFieldBeginWithName:fieldName type:fieldType fieldID:aField.index];
    
    [self _writeValue:fieldValue
             forField:aField
           toProtocol:outProtocol];
    
    [outProtocol writeFieldEnd];
  }
  
  [outProtocol writeFieldStop];
  [outProtocol writeStructEnd];
}

+ (void) sendMessage:(NSString *)messageName
          toProtocol:(id<ENTProtocol>)outProtocol
        withArgPairs:(NSArray *)argPairs
{
  [outProtocol writeMessageBeginWithName: messageName type: TMessageType_CALL sequenceID: 0];
  [outProtocol writeStructBeginWithName: [messageName stringByAppendingString:@"_args"]];

  for (NSArray *anArgumentPair in argPairs) {
    if ([anArgumentPair count] != 2) {
      continue;
    }
    
    FATField *field = [anArgumentPair objectAtIndex:0];
    id fieldValue = [anArgumentPair objectAtIndex:1];
    
    [outProtocol writeFieldBeginWithName:field.name type:field.type fieldID:field.index];
    [self _writeValue:fieldValue
             forField:field
           toProtocol:outProtocol];
    [outProtocol writeFieldEnd];
  }
  
  [outProtocol writeFieldStop];
  [outProtocol writeStructEnd];
  [outProtocol writeMessageEnd];
  [[outProtocol transport] flush];
}

@end
