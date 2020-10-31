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
#import "ENSDKLogging.h"

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

- (void)invokeAsyncBoolBlock:(BOOL(^)(void))block completion:(void (^)(BOOL val, NSError *error))completion
{
    dispatch_async(self.queue, ^(void) {
        __block BOOL retVal = NO;
        @try {
            retVal = block();
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(retVal, nil);
            });
        }
        @catch (NSException *exception) {
            NSError * error = [ENError errorFromException:exception];
            completion(NO, error);
            [self handleError:error];
        }
    });
}

- (void)invokeAsyncInt32Block:(int32_t(^)(void))block completion:(void (^)(int32_t val, NSError *_Nullable error))completion
{
    dispatch_async(self.queue, ^(void) {
        __block int32_t retVal = -1;
        @try {
            retVal = block();
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(retVal, nil);
            });
        }
        @catch (NSException *exception) {
            NSError * error = [ENError errorFromException:exception];
            completion(-1, error);
            [self handleError:error];
        }
    });
}

// use id instead of NSObject* so block type-checking is happy
- (void)invokeAsyncObjectBlock:(nullable id(^)(void))block completion:(void (^)(id _Nullable val, NSError *_Nullable error))completion

{
    dispatch_async(self.queue, ^(void) {
        id retVal = nil;
        @try {
            retVal = block();
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(retVal, nil);
            });
        }
        @catch (NSException *exception) {
            NSError * error = [ENError errorFromException:exception];
            completion(nil, error);
            [self handleError:error];
        }
    });
}

- (void)invokeAsyncBlock:(void(^)(void))block completion:(void (^)(NSError *_Nullable error))completion
{
    dispatch_async(self.queue, ^(void) {
        @try {
            block();
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
        @catch (NSException *exception) {
            NSError * error = [ENError errorFromException:exception];
            completion(error);
            [self handleError:error];
        }
    });
}

#pragma mark - Private routines

- (void)handleError:(NSError *)error
{
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
