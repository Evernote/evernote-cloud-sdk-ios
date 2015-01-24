/*
 * Copyright (c) 2012-2014 by Evernote Corporation, All rights reserved.
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

#import "ENStoreClient.h"
#import "ENError.h"
#import "EDAMErrors.h"
#import "ENSDKPrivate.h"

NSString * ENStoreClientDidFailWithAuthenticationErrorNotification = @"ENStoreClientDidFailWithAuthenticationErrorNotification";

@interface ENStoreClient ()
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation ENStoreClient

- (id)init
{
    self = [super init];
    if (self) {
        NSString * queueName = [NSString stringWithFormat:@"com.evernote.sdk.%@", NSStringFromClass([self class])];
        self.queue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    }
    return self;
}

- (void)invokeAsyncBoolBlock:(BOOL(^)())block
                     success:(void(^)(BOOL val))success
                     failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.queue, ^(void) {
        __block BOOL retVal = NO;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            [self handleException:exception withFailureBlock:failure];
        }
    });
}

- (void)invokeAsyncInt32Block:(int32_t(^)())block
                      success:(void(^)(int32_t val))success
                      failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.queue, ^(void) {
        __block int32_t retVal = -1;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            [self handleException:exception withFailureBlock:failure];
        }
    });
}

// use id instead of NSObject* so block type-checking is happy
- (void)invokeAsyncIdBlock:(id(^)())block
                   success:(void(^)(id))success
                   failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.queue, ^(void) {
        id retVal = nil;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            [self handleException:exception withFailureBlock:failure];
        }
    });
}

- (void)invokeAsyncVoidBlock:(void(^)())block
                     success:(void(^)())success
                     failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.queue, ^(void) {
        @try {
            if (block) {
                block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success();
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            [self handleException:exception withFailureBlock:failure];
        }
    });
}

#pragma mark - Private routines

- (void)handleException:(NSException *)exception withFailureBlock:(void(^)(NSError *error))failure
{
    NSError * error = [ENError errorFromException:exception];
    if (failure) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
    }
    
    // If this is a hard auth error, then send a notification about it. This is intended to trigger for
    // tokens that have either expired or that have been revoked. This does NOT include permissions
    // denials (ie, the auth token is valid, but not for the operation you're trying to do with it). Those
    // are generally program errors.
    int edamErrorCode = [error.userInfo[@"EDAMErrorCode"] intValue];
    if (edamErrorCode > 0 &&
        (edamErrorCode == EDAMErrorCode_AUTH_EXPIRED ||
         edamErrorCode == EDAMErrorCode_INVALID_AUTH)) {
        ENSDKLogError(@"ENStoreClient got authentication EDAM error %u", edamErrorCode);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ENStoreClientDidFailWithAuthenticationErrorNotification object:self];
        });
    }
}
@end
