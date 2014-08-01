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
 *  This class represents a notebook in the Evernote service.
 */
@interface ENNotebook : NSObject <NSCoding>

/**
 *  The name of the notebook.
 */
@property (nonatomic, readonly) NSString * name;

/**
 *  The best-available display name for the owner of this notebook.
 */
@property (nonatomic, readonly) NSString * ownerDisplayName;

/**
 *  A flag indicating if this notebook is read/write for the current user.
 */
@property (nonatomic, readonly) BOOL allowsWriting;

/**
 *  A flag indicating if this notebook is shared. Being shared means it is visible to other users.
 *  Either it is a notebook that the current user created and shared,
 *  or one that was shared by someone else but joined by the current user.
 */
@property (nonatomic, readonly) BOOL isShared;

/**
 *  A flag indicating if this notebook is the user's own shared notebook with others
 */
@property (nonatomic, readonly) BOOL isOwnShared;

/**
 *  A flag indicating if this notebook is the user's joined shared notebook from others
 */
@property (nonatomic, readonly) BOOL isJoinedShared;

/**
 *  A flag indicating if this notebook is public. Being public means it is visible to everyone.
 *  Either it is a notebook that the current user created and shared publicly,
 *  or one that was shared publicly by someone else but joined by the current user.
 */
@property (nonatomic, readonly) BOOL isPublic;

/**
 *  A flag indicating if this notebook is the user's own public notebook
 */
@property (nonatomic, readonly) BOOL isOwnPublic;

/**
 *  A flag indicating if this notebook is the user's joined public notebook. A joined public notebook does 
 *  not need authentication to see the content, and joined users only have read permission
 */
@property (nonatomic, readonly) BOOL isJoinedPublic;

/**
 *  A flag indicating whether this notebook exists in the user's business.
 */
@property (nonatomic, readonly) BOOL isBusinessNotebook;

/**
 *  A flag indicating whether this notebook is "owned" by the current user. In this context, "owned"
 *  indicates either a notebook within the user's personal account (shared with others or not), or a business
 *  notebook that this user is the contact for (generally due to them being the creator).
 */
@property (nonatomic, readonly) BOOL isOwnedByUser;

/**
 *  A flag indicating whether this notebook is the user's "default" notebook; e.g. the notebook
 *  that will be used as an upload destination if none is specified. (Apps using "App Notebook" auth will
 *  see this flag appear to be YES on their sole notebook even if the user has some other "default" notebook
 *  set using full Evernote clients.)
 */
@property (nonatomic, readonly) BOOL isDefaultNotebook;
@end
