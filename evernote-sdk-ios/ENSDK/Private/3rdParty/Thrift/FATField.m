/*
 * FATField.m
 * evernote-sdk-ios
 *
 * Copyright 2014 Evernote Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "FATField.h"
#import "ENTProtocol.h"

@implementation FATField

+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
{
  FATField *field = [[[self class] alloc] init];
  field.index = index;
  field.type = type;
  field.optional = optional;
  field.name = name;
  return field;
}

+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                    structClass:(Class)structClass
{
  FATField *field = [self fieldWithIndex:index
                                    type:type
                                optional:optional
                                    name:name];
  field.structClass = structClass;
  return field;
}

+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                     valueField:(FATField *)valueField
{
  FATField *field = [self fieldWithIndex:index
                                    type:type
                                optional:optional
                                    name:name];
  field.valueField = valueField;
  return field;
}

+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                       keyField:(FATField *)keyField
                     valueField:(FATField *)valueField
{
  FATField *field = [self fieldWithIndex:index
                                    type:type
                                optional:optional
                                    name:name
                              valueField:valueField];
  field.keyField = keyField;
  return field;
}


+ (NSString *) nameForFatFieldType:(uint32_t)type {
  switch (type) {
    case TType_VOID:
      return @"Void";
    case TType_BOOL:
      return @"Boolean";
    case TType_BYTE:
      return @"Byte";
    case TType_DOUBLE:
      return @"Double";
    case TType_I16:
      return @"Int16";
    case TType_I32:
      return @"Int32";
    case TType_I64:
      return @"Int64";
    case TType_STRING:
      return @"String";
    case TType_STRUCT:
      return @"Struct";
    case TType_MAP:
      return @"Map";
    case TType_SET:
      return @"Set";
    case TType_LIST:
      return @"List";
    case TType_BINARY:
      return @"Binary";
  }
  return @"unknown!";
}

- (NSString *) description {
  NSMutableString *ms = [NSMutableString string];
  [ms appendString:@"<"];
  [ms appendString:NSStringFromClass([self class])];
  [ms appendFormat:@": %p;", self];
  
  [ms appendFormat:@" index = %i; ", self.index];
  [ms appendFormat:@" type = %i; ", self.type];
  [ms appendFormat:@" optional = %@; ", self.optional ? @"YES" : @"NO"];
  [ms appendFormat:@" name = %@; ", self.name];
  
  if (self.type == TType_STRUCT) {
    [ms appendFormat:@" structClass = %@; ", NSStringFromClass(self.structClass)];
  }
  else if (self.type == TType_SET || self.type == TType_LIST || self.type == TType_MAP) {
    [ms appendFormat:@" valueField = %@; ", self.valueField];
  }
  
  if (self.type == TType_MAP) {
    [ms appendFormat:@" keyField = %@; ", self.keyField];
  }
  
  [ms appendString:@">"];
  return ms;
}

@end

@implementation FATArgument

+ (instancetype) argumentWithField:(FATField *)field value:(id)value {
  FATArgument *argument = [[self alloc] init];
  argument.field = field;
  argument.value = value;
  return argument;
}

@end
