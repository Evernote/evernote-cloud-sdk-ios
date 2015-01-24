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

#import "ENError.h"
#import "EDAM.h"

#if !__has_feature(objc_arc)
#error Evernote iOS SDK must be built with ARC.
// You can turn on ARC for only Evernote SDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

NSString * ENErrorDomain = @"ENErrorDomain";

@implementation ENError

+ (NSError *)connectionFailedError
{
    return [NSError errorWithDomain:ENErrorDomain
                               code:ENErrorCodeConnectionFailed
                           userInfo:@{NSLocalizedDescriptionKey: @"Connection failed to Evernote Service."}];
}

+ (NSError *)noteSizeLimitReachedError
{
    return [NSError errorWithDomain:ENErrorDomain
                               code:ENErrorCodeLimitReached
                           userInfo:@{NSLocalizedDescriptionKey: @"Note exceeded size limit to upload."}];
}

+ (NSError *)errorFromException:(NSException *)exception
{
    if (exception) {
        NSInteger sanitizedErrorCode = ENErrorCodeUnknown;
        NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
        
        if ([exception respondsToSelector:@selector(errorCode)]) {
            // Evernote Thrift exception classes have an errorCode property
            int edamErrorCode = [[(id)exception errorCode] intValue];
            sanitizedErrorCode = [[self class] sanitizedErrorCodeFromEDAMErrorCode:edamErrorCode];
            userInfo[@"EDAMErrorCode"] = @(edamErrorCode); // Put this in the user info in case the caller cares.
            if (userInfo[NSLocalizedDescriptionKey] == nil) {
                userInfo[NSLocalizedDescriptionKey] = [[self class] localizedDescriptionForENErrorCode:sanitizedErrorCode];
            }
        } else if ([exception isKindOfClass:[ENTException class]]) {
            // treat any Thrift errors as a transport error
            // we could create separate error codes for the various TException subclasses
            sanitizedErrorCode = ENErrorCodeConnectionFailed;
            if ([exception.description length] > 0) {
                userInfo[NSLocalizedDescriptionKey] = exception.description;
            }
        }
        
        if ([exception isKindOfClass:[EDAMSystemException class]] == YES) {
            EDAMSystemException* systemException = (EDAMSystemException*)exception;
            if (systemException.rateLimitDuration) {
                userInfo[@"rateLimitDuration"] = [systemException rateLimitDuration];
            }
            if (systemException.message) {
                userInfo[@"message"] = [systemException message];
            }
        } else if ([exception isKindOfClass:[EDAMNotFoundException class]]) {
            EDAMNotFoundException * notFound = (EDAMNotFoundException *)exception;
            userInfo[@"parameter"] = notFound.identifier;
            sanitizedErrorCode = ENErrorCodeNotFound;
        }
        
        if ([exception respondsToSelector:@selector(parameter)]) {
            NSString * parameter = [(id)exception parameter];
            if (parameter) {
                userInfo[@"parameter"] = parameter;
            }
        }
        
        return [NSError errorWithDomain:ENErrorDomain code:sanitizedErrorCode userInfo:userInfo];
    }
    return nil;
}

+ (ENErrorCode)sanitizedErrorCodeFromEDAMErrorCode:(int)code
{
    switch (code) {
        case EDAMErrorCode_BAD_DATA_FORMAT:
        case EDAMErrorCode_DATA_REQUIRED:
        case EDAMErrorCode_LEN_TOO_LONG:
        case EDAMErrorCode_LEN_TOO_SHORT:
        case EDAMErrorCode_TOO_FEW:
        case EDAMErrorCode_TOO_MANY:
            return ENErrorCodeInvalidData;
            
        case EDAMErrorCode_AUTH_EXPIRED:
            return ENErrorCodeAuthExpired;
            
        case EDAMErrorCode_DATA_CONFLICT:
            return ENErrorCodeDataConflict;
            
        case EDAMErrorCode_ENML_VALIDATION:
            return ENErrorCodeENMLInvalid;
            
        case EDAMErrorCode_INVALID_AUTH:
        case EDAMErrorCode_PERMISSION_DENIED:
            return ENErrorCodePermissionDenied;
            
        case EDAMErrorCode_LIMIT_REACHED:
            return ENErrorCodeLimitReached;
            
        case EDAMErrorCode_QUOTA_REACHED:
            return ENErrorCodeQuotaReached;
            
        case EDAMErrorCode_RATE_LIMIT_REACHED:
            return ENErrorCodeRateLimitReached;
            
        default:
            return ENErrorCodeUnknown;
    }
}

+ (NSString *)localizedDescriptionForENErrorCode:(ENErrorCode)code {
    switch (code) {
        case ENErrorCodeInvalidData:
            return @"Invalid note data.";
            
        case ENErrorCodeAuthExpired:
            return @"Authentication for Evernote Service expired. Please login again.";
            
        case ENErrorCodeDataConflict:
            return @"Conflict note data.";
            
        case ENErrorCodeENMLInvalid:
            return @"ENML for note is invalid.";
            
        case ENErrorCodePermissionDenied:
            return @"Permission denied for operation.";
            
        case ENErrorCodeLimitReached:
            return @"Note exceeded size limit to upload.";
            
        case ENErrorCodeQuotaReached:
            return @"User has run out of upload quota to Evernote.";
            
        case ENErrorCodeRateLimitReached:
            return @"Application reached hourly API call limit to Evernote.";
            
        default:
            return @"Unknown error";
    }
}

@end
