/*
 * FATObject.m
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

#import "FATObject.h"
#import "FATField.h"
#import <objc/runtime.h>

void FATInvalidAbstractInvocation(SEL selector, Class class) {
  [NSException raise:NSInvalidArgumentException
              format:@"-%@ only defined for abstract class. Define -[%@ %@]!",
   NSStringFromSelector(selector),
   NSStringFromClass(class),
   NSStringFromSelector(selector)
   ];
}


@implementation FATObject

+ (NSString *) structName {
  FATInvalidAbstractInvocation(_cmd, self);
  return nil;
}

+ (NSArray *) structFields {
  FATInvalidAbstractInvocation(_cmd, self);
  return nil;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if (self != nil) {
    NSArray *structFields = [[self class] structFields];
    for (FATField *aField in structFields) {
      NSString *fieldName = aField.name;
      if ([aDecoder containsValueForKey:fieldName] == NO) {
        continue;
      }
      
      id fieldValue = [aDecoder decodeObjectForKey:fieldName];
      [self setValue:fieldValue
              forKey:fieldName];
    }
  }
  return self;
}

- (void) read: (id <ENTProtocol>) inProtocol {
  [ENTProtocolUtil readFromProtocol:inProtocol
                       ontoObject:self];
}

- (void) write: (id <ENTProtocol>) outProtocol {
  [ENTProtocolUtil writeObject:self
                ontoProtocol:outProtocol];
}

- (instancetype) copyWithZone:(NSZone *)zone {
  FATObject *copy = [[[self class] allocWithZone:zone] init];
  NSArray *structFields = [[self class] structFields];
  for (FATField *aField in structFields) {
    [copy setValue:[self valueForKey:aField.name]
            forKey:aField.name];
  }
  return copy;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
  NSArray *structFields = [[self class] structFields];
  for (FATField *aField in structFields) {
    NSString *fieldName = aField.name;
    id fieldValue = [self valueForKey:fieldName];
    if (fieldValue == nil) {
      continue;
    }

    [aCoder encodeObject:fieldValue forKey:fieldName];
  }
}

- (BOOL) isEqual:(id)object {
  if ([object isKindOfClass:[self class]] == NO) {
    return NO;
  }
  
  NSArray *ourFields = [[self class] structFields];
  NSArray *theirFields = [[object class] structFields];
  if ([ourFields isEqualToArray:theirFields] == NO) {
    return NO;
  }
  
  for (FATField *aField in ourFields) {
    NSString *fieldName = aField.name;
    id ourValue = [self valueForKey:fieldName];
    id theirValue = [object valueForKey:fieldName];
    if (ourValue != theirValue && [ourValue isEqual:theirValue] == NO) {
      return NO;
    }
  }
  return YES;
}

- (NSUInteger)hash {
  NSMutableArray *fieldValues = [NSMutableArray array];
  NSArray *structFields = [[self class] structFields];
  for (FATField *aField in structFields) {
    id fieldValue = [self valueForKey:aField.name];
    if (fieldValue == nil) {
      [fieldValues addObject:[NSNull null]];
    }
    else {
      [fieldValues addObject:fieldValue];
    }
  }
  return [fieldValues hash];
}

#pragma mark -
#pragma mark
- (NSString *) description {
  NSMutableString *ms = [NSMutableString string];
  [ms appendString:@"<"];
  [ms appendString:NSStringFromClass([self class])];
  [ms appendFormat:@": %p;", self];

  NSArray *structFields = [[self class] structFields];
  for (FATField *aField in structFields) {
    [ms appendFormat:@" %@ = %@;", aField.name, [self valueForKey:aField.name]];
  }
  
  [ms appendString:@">"];
  return ms;
}

@end

@implementation FATException

+ (void) initialize {
  if (self != [FATException class]) {
    return;
  }
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    unsigned int fatObjectMethodCount = 0;
    Method *fatObjectMethods = class_copyMethodList([FATObject class], &fatObjectMethodCount);
    for (int i=0; i<fatObjectMethodCount; i++) {
      class_addMethod([self class],
                      method_getName(fatObjectMethods[i]),
                      method_getImplementation(fatObjectMethods[i]),
                      method_getTypeEncoding(fatObjectMethods[i]));
    }
    free(fatObjectMethods);
  });
}

+ (NSString *) structName {
  FATInvalidAbstractInvocation(_cmd, self);
  return nil;
}

+ (NSArray *) structFields {
  FATInvalidAbstractInvocation(_cmd, self);
  return nil;
}

- (instancetype) init {
  return [self initWithName:NSStringFromClass([self class])
                     reason:@"unknown"
                   userInfo:nil];
}

- (void) read: (id <ENTProtocol>) inProtocol {
  [ENTProtocolUtil readFromProtocol:inProtocol
                       ontoObject:self];
}

- (void) write: (id <ENTProtocol>) outProtocol {
  [ENTProtocolUtil writeObject:self
                ontoProtocol:outProtocol];
}

@end
