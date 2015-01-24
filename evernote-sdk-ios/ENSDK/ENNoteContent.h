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

/**
 *  This class represents the content of a note.
 */
@interface ENNoteContent : NSObject

/**
 *  Class method to create a note content object from a plaintext string.
 *
 *  @param string A plaintext string.
 *
 *  @return A valid note content instance.
 */
+ (instancetype)noteContentWithString:(NSString *)string;

/**
 *  Class method to create a note content object for a content array
 *
 *  @param contentArray NSArray containing NSString or UIImage objects
 *
 *  @return A valid note content instance.
 */
+ (instancetype)noteContentWithContentArray:(NSArray *)contentArray;

/**
 *  Class method to create a note content object from a string of sanitized HTML string. 
 *  "Sanitized" HTML means that any desired CSS styles are inlined into the DOM (versus being
 *  remote resources or a single <style> block.)
 *
 *  NB If you have an HTML source that's not already sanitized, you can load it into a UIWebView and
 *  use +[ENNote populateNoteFromWebView:completion:] to capture it.
 *
 *  @param Sanitized HTML string.
 *
 *  @return A valid note content instance.
 */
+ (instancetype)noteContentWithSanitizedHTML:(NSString *)html;

@end
