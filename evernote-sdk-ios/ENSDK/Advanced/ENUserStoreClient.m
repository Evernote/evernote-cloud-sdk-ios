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

#import "ENUserStoreClient.h"
#import "ENSDKPrivate.h"
#import "ENTBinaryProtocol.h"
#import "ENTHTTPClient.h"

@interface ENUserStoreClient ()
@property (nonatomic, strong) EDAMUserStoreClient * client;
@property (nonatomic, strong) NSString * authenticationToken;
@end

@implementation ENUserStoreClient
+ (instancetype)userStoreClientWithUrl:(NSString *)url authenticationToken:(NSString *)authenticationToken
{
    return [[self alloc] initWithUserStoreUrl:url authenticationToken:authenticationToken];
}

- (id)initWithUserStoreUrl:(NSString *)userStoreUrl authenticationToken:(NSString *)authenticationToken
{
    self = [super init];
    if (self) {
        NSURL * url = [NSURL URLWithString:userStoreUrl];
        ENTHTTPClient * transport = [[ENTHTTPClient alloc] initWithURL:url];
        ENTBinaryProtocol * protocol = [[ENTBinaryProtocol alloc] initWithTransport:transport];
        self.client = [[EDAMUserStoreClient alloc] initWithProtocol:protocol];
        self.authenticationToken = authenticationToken;
    }
    return self;
}

#pragma mark - Private Synchronous Helpers

- (EDAMAuthenticationResult *)authenticateToBusiness
{
    return [self.client authenticateToBusiness:self.authenticationToken];
}

#pragma mark - UserStore methods

- (void)checkVersionWithClientName:(NSString *)clientName
                  edamVersionMajor:(int16_t)edamVersionMajor
                  edamVersionMinor:(int16_t)edamVersionMinor
                           success:(void(^)(BOOL versionOK))success
                           failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncBoolBlock:^BOOL{
        return [self.client checkVersion:clientName edamVersionMajor:edamVersionMajor edamVersionMinor:edamVersionMinor];
    } success:success failure:failure];
}

- (void)getBootstrapInfoWithLocale:(NSString *)locale
                           success:(void(^)(EDAMBootstrapInfo *info))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getBootstrapInfo:locale];
    } success:success failure:failure];
}

- (void)getUserWithSuccess:(void(^)(EDAMUser *user))success
                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getUser:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getPublicUserInfoWithUsername:(NSString *)username
                              success:(void(^)(EDAMPublicUserInfo *info))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getPublicUserInfo:username];
    } success:success failure:failure];
}

- (void)getPremiumInfoWithSuccess:(void(^)(EDAMPremiumInfo *info))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getPremiumInfo:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getNoteStoreUrlWithSuccess:(void(^)(NSString *noteStoreUrl))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteStoreUrl:self.authenticationToken];
    } success:success failure:failure];
}

- (void)authenticateToBusinessWithSuccess:(void(^)(EDAMAuthenticationResult *authenticationResult))success
                                  failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client authenticateToBusiness:self.authenticationToken];
    } success:success failure:failure];
}

- (void)revokeLongSessionWithAuthenticationToken:(NSString*)authenticationToken
                                         success:(void(^)())success
                                         failure:(void(^)(NSError *error))failure {
    [self invokeAsyncVoidBlock:^void {
        [self.client revokeLongSession:authenticationToken];
    } success:success failure:failure];
}
@end
