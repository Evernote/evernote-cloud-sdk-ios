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
 *  A note search represents a search query for the Evernote service used in finding notes.
 */
@interface ENNoteSearch : NSObject

/**
 *  The search in the Evernote search grammar.
 */
@property (nonatomic, readonly) NSString * searchString;

/**
 *  Class method to get a new search object from a raw search string. 
 *  You can use the full search grammar as described at http://dev.evernote.com/doc/articles/search_grammar.php
 *
 *  @param searchString A search string.
 *
 *  @return A note search object.
 */
+ (instancetype)noteSearchWithSearchString:(NSString *)searchString;

/**
 *  Class method to get a new search object that represents all notes created by this application.
 *  "This application" is based on the sourceApplication property on ENSession.
 *
 *  @return A note search object.
 */
+ (instancetype)noteSearchCreatedByThisApplication;

/**
 *  The designated initializer for a note search, from a raw search string.
 *  You can use the full search grammar as described at http://dev.evernote.com/doc/articles/search_grammar.php
 *
 *  @param searchString A search string.
 *
 *  @return An initialized note search object.
 */
- (id)initWithSearchString:(NSString *)searchString;
@end
