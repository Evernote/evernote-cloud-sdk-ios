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

#import <Foundation/Foundation.h>

#import "ENTProtocol.h"

@interface FATField : NSObject

@property (assign) uint32_t index;
@property (assign) uint32_t type;
@property (assign) BOOL optional;
@property (strong, nonatomic) NSString *name;

// Only applicable for TType_SET, TType_LIST, TType_MAP, TType_Struct
@property (assign) uint32_t valueType;
@property (assign) Class valueClass;

// Only applicable for TType_MAP
@property (assign) uint32_t keyType;
@property (assign) Class keyClass;


+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name;

// Only applicable for TType_SET, TType_LIST, TType_MAP, TType_Struct
+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                      valueType:(int)valueType
                     valueClass:(Class)valueClass; // valueClass may be NULL

// Only applicable for TType_MAP
+ (instancetype) fieldWithIndex:(uint32_t)index
                           type:(uint32_t)type
                       optional:(BOOL)optional
                           name:(NSString *)name
                        keyType:(int)keyType
                       keyClass:(Class)keyClass    // keyClass may be NULL
                      valueType:(int)valueType
                     valueClass:(Class)valueClass; // valueClass may be NULL


@end
