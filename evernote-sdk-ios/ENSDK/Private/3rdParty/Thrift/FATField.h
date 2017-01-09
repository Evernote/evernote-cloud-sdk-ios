/*
 * FATField.h
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

#import <Foundation/Foundation.h>

#import "ENTProtocol.h"

@interface FATField : NSObject

@property (assign) uint32_t index;
@property (assign) uint32_t type;
@property (assign) BOOL optional;
@property (strong, nonatomic) NSString *name;

// Only applicable for TType_Struct
@property (assign, nonatomic) Class structClass;

// Only applicable for TType_SET, TType_LIST, TType_MAP, TType_Struct
@property (strong, nonatomic) FATField *valueField;

// Only applicable for TType_MAP
@property (strong, nonatomic) FATField *keyField;


+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name;

+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                    structClass:(Class)structClass;

// Only applicable for TType_SET, TType_LIST, TType_MAP, TType_Struct
+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                     valueField:(FATField *)valueField;

// Only applicable for TType_MAP
+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                       keyField:(FATField *)keyField
                     valueField:(FATField *)valueField;

@end

@interface FATArgument : NSObject

+ (instancetype) argumentWithField:(FATField *)field value:(id)value;

@property (strong, nonatomic) FATField *field;
@property (strong, nonatomic) id value;

@end
