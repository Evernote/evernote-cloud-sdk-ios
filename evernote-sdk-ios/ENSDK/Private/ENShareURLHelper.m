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

#import "ENShareURLHelper.h"

@implementation ENShareURLHelper
+ (NSString *)shareURLStringForNoteGUID:(NSString *)guid
                                shardId:(NSString *)shardId
                               shareKey:(NSString *)shareKey
                            serviceHost:(NSString *)serviceHost
                encodedAdditionalString:(NSString *)encodedAdditionalString
{
    // All of the standard pieces of information come from the service in string format. We need their underlying bytes/numeric
    // values to create a packed byte array. Get the correct values for each, and if any of them appear not to be in the expected
    // format, fall back to the long form share URL.
    
    // Shard ID to number
    NSInteger shardNumber = -1;
    if (shardId.length > 1 && [shardId hasPrefix:@"s"]) {
        // Ignore the leading "s" character.
        NSString * shardString = [shardId substringFromIndex:1];
        // Have to use a scanner here to be fully defensive, since "s0" is not technically invalid.
        NSScanner * scanner = [NSScanner scannerWithString:shardString];
        if (![scanner scanInteger:&shardNumber]) {
            shardNumber = -1;
        }
        if (shardNumber > UINT16_MAX) {
            shardNumber = -1;
        }
    }
    
    // Note guid to UUID
    NSUUID * noteUUID = [[NSUUID alloc] initWithUUIDString:guid];

    // Share key to binary value. First truncate it to inital 16 character (it's normally 32).
    NSData * shareKeyData = nil;
    if (shareKey.length >= 16) {
        shareKeyData = DataFromHexString([shareKey substringToIndex:16]);
    }
    
    // Check that all our values appear valid. If not, return the old style share URL instead.
    if (shardNumber < 0  || !noteUUID || !shareKeyData) {
        return [NSString stringWithFormat:@"https://%@/shard/%@/sh/%@/%@", serviceHost, shardId, guid, shareKey];
    }
    
    // All the data looks sane. Concatenate all three components into one buffer.
    NSUInteger shareDataCapacity = sizeof(uint16_t) + sizeof(uuid_t) + shareKeyData.length; // == 26 bytes
    NSMutableData * shareData = [[NSMutableData alloc] initWithCapacity:shareDataCapacity];
    
    // Cast to uint16_t is safe because we've already bailed out if the value would truncate.
    uint16_t shardNumber16Big = CFSwapInt16HostToBig((uint16_t)shardNumber);
    
    [shareData appendBytes:&shardNumber16Big length:sizeof(uint16_t)];
    uuid_t uuidRaw;
    [noteUUID getUUIDBytes:uuidRaw];
    [shareData appendBytes:uuidRaw length:sizeof(uuid_t)];
    
    [shareData appendData:shareKeyData];
    
    // Encode this as base 64.
    NSString * shareDataString = [shareData base64EncodedStringWithOptions:0];
    // Remove the trailing pad byte, and substitute for the URL safe variants of the upper two table values.
    // See http://tools.ietf.org/html/rfc4648#page-7
    // (In a whiteboard interview, we would do this in-place in one pass through the string! We're not, for
    // clarity's sake, and because this is cheap and we're not doing it very often.)
    shareDataString = [shareDataString substringToIndex:shareDataString.length-1];
    shareDataString = [shareDataString stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    shareDataString = [shareDataString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    
    NSString * finalUrlString = [NSString stringWithFormat:@"https://%@/l/%@", serviceHost, shareDataString];
    if (encodedAdditionalString.length > 0) {
        finalUrlString = [finalUrlString stringByAppendingFormat:@"/%@", encodedAdditionalString];
    }
    return finalUrlString;
}

// Returns a positive value between [0, 15]. Negative values mean it wasn't a hex digit.
static int ValueFromHexChar(unichar ch)
{
    int val = -1;
    if (ch <= '9') {
        val = ch - '0';
    } else if (ch <= 'F') {
        val = ch - 'A' + 10;
    } else if (ch <= 'f') {
        val = ch - 'a' + 10;
    }
    return (val > 0xF) ? -1 : val;
}

static NSData * DataFromHexString(NSString * hexString)
{
    if (hexString.length % 2 != 0) {
        return nil;
    }
    NSMutableData * data = [[NSMutableData alloc] initWithCapacity:(hexString.length / 2)];
    for (NSUInteger i = 0; i < hexString.length; i += 2) {
        int high = ValueFromHexChar([hexString characterAtIndex:i]);
        int low = ValueFromHexChar([hexString characterAtIndex:i+1]);
        if (high < 0 || low < 0) {
            return nil;
        }
        uint8_t byte = (high << 4 | low);
        [data appendBytes:&byte length:1];
    }
    return data;
}
@end
