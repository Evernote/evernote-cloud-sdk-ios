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

#import "ENNoteStoreClient.h"
#import "ENSDKPrivate.h"
#import "ENAuthCache.h"
#import "EDAMNoteStoreClient+Utilities.h"
#import "ENTHTTPClient.h"
#import "ENTBinaryProtocol.h"
#import "ENSession.h"

// This is the Evernote standard reasonable recommendation for a single findNotes call and won't break in future.
#define FIND_NOTES_DEFAULT_MAX_NOTES 100

@interface ENNoteStoreClient ()
@property (nonatomic, strong) EDAMNoteStoreClient * client;
@property (nonatomic, copy) NSString * cachedNoteStoreUrl;
@property (nonatomic, copy) NSString * cachedAuthenticationToken;
@end

@implementation ENNoteStoreClient
+ (instancetype)noteStoreClientWithUrl:(NSString *)url authenticationToken:(NSString *)authenticationToken
{
    ENNoteStoreClient * client = [[self alloc] init];
    client.cachedNoteStoreUrl = url;
    client.cachedAuthenticationToken = authenticationToken;
    return client;
}

#pragma mark - Override points for subclasses

// Override points for subclasses that handle auth differently. This simple version just
// returns the cached token and cached url
- (NSString *)authenticationToken
{
    return self.cachedAuthenticationToken;
}

- (NSString *)noteStoreUrl
{
    return self.cachedNoteStoreUrl;
}

#pragma mark - End override points

- (void)setUploadProgressHandler:(ENNoteStoreClientProgressHandler)uploadProgressHandler
{
    _uploadProgressHandler = uploadProgressHandler;
    [self updateProgressHandlers];
}

- (void)setDownloadProgressHandler:(ENNoteStoreClientProgressHandler)downloadProgressHandler
{
    _downloadProgressHandler = downloadProgressHandler;
    [self updateProgressHandlers];
}

- (void)updateProgressHandlers
{
    // Uses the _client ivar here since we're called from within the -client getter.
    if (_client) {
        if (self.uploadProgressHandler) {
            ENNoteStoreClientProgressHandler uploadHandler = self.uploadProgressHandler;
            [_client setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                if (totalBytesExpectedToWrite > 0) {
                    CGFloat t = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite;
                    uploadHandler(t);
                }
            }];
        } else {
            [_client setUploadProgressBlock:nil];
        }
        
        if (self.downloadProgressHandler) {
            ENNoteStoreClientProgressHandler downloadHandler = self.downloadProgressHandler;
            [_client setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                if (totalBytesExpectedToRead > 0) {
                    CGFloat t = (CGFloat)totalBytesRead / (CGFloat)totalBytesExpectedToRead;
                    downloadHandler(t);
                }
            }];
        } else {
            [_client setDownloadProgressBlock:nil];
        }
    }
}

- (EDAMNoteStoreClient *)client
{
    if (!_client) {
        NSString * noteStoreUrl = [self noteStoreUrl];
        NSURL * url = [NSURL URLWithString:noteStoreUrl];
        ENTHTTPClient * transport = [[ENTHTTPClient alloc] initWithURL:url];
        ENTBinaryProtocol * protocol = [[ENTBinaryProtocol alloc] initWithTransport:transport];
        _client = [[EDAMNoteStoreClient alloc] initWithProtocol:protocol];
        
        // Bind progress handlers if they are pending attachment.
        [self updateProgressHandlers];
    }
    return _client;
}

#pragma mark - Private Synchronous Helpers

- (EDAMAuthenticationResult *)authenticateToSharedNotebookWithGlobalId:(NSString *)globalId
{
    return [self.client authenticateToSharedNotebook:globalId authenticationToken:self.authenticationToken];
}

#pragma mark - NoteStore sync methods

- (void)getSyncStateWithSuccess:(void(^)(EDAMSyncState *syncState))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getSyncState:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getSyncChunkAfterUSN:(int32_t)afterUSN
                  maxEntries:(int32_t)maxEntries
                fullSyncOnly:(BOOL)fullSyncOnly
                     success:(void(^)(EDAMSyncChunk *syncChunk))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getSyncChunk:self.authenticationToken afterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly];
    } success:success failure:failure];
}

- (void)getFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                          maxEntries:(int32_t)maxEntries
                              filter:(EDAMSyncChunkFilter *)filter
                             success:(void(^)(EDAMSyncChunk *syncChunk))success
                             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getFilteredSyncChunk:self.authenticationToken afterUSN:afterUSN maxEntries:maxEntries filter:filter];
    } success:success failure:failure];
}

- (void)getLinkedNotebookSyncState:(EDAMLinkedNotebook *)linkedNotebook
                           success:(void(^)(EDAMSyncState *syncState))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getLinkedNotebookSyncState:self.authenticationToken linkedNotebook:linkedNotebook];
    } success:success failure:failure];
}

#pragma mark - NoteStore notebook methods

- (void)listNotebooksWithSuccess:(void(^)(NSArray *notebooks))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listNotebooks:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getNotebookWithGuid:(EDAMGuid)guid
                    success:(void(^)(EDAMNotebook *notebook))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNotebook:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getLinkedNotebookSyncChunk:(EDAMLinkedNotebook *)linkedNotebook
                          afterUSN:(int32_t)afterUSN
                        maxEntries:(int32_t) maxEntries
                      fullSyncOnly:(BOOL)fullSyncOnly
                           success:(void(^)(EDAMSyncChunk *syncChunk))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getLinkedNotebookSyncChunk:self.authenticationToken linkedNotebook:linkedNotebook afterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly];
    } success:success failure:failure];
}

- (void)getDefaultNotebookWithSuccess:(void(^)(EDAMNotebook *notebook))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getDefaultNotebook:self.authenticationToken];
    } success:success failure:failure];
}

- (void)createNotebook:(EDAMNotebook *)notebook
               success:(void(^)(EDAMNotebook *notebook))success
               failure:(void(^)(NSError *error))failure
{
    [[ENSession sharedSession] listNotebooks_cleanCache];
    [self invokeAsyncIdBlock:^id {
        return [self.client createNotebook:self.authenticationToken notebook:notebook];
    } success:success failure:failure];
}

- (void)updateNotebook:(EDAMNotebook *)notebook
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateNotebook:self.authenticationToken notebook:notebook];
    } success:success failure:failure];
}

- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                        success:(void(^)(int32_t usn))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNotebook:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore tags methods

- (void)listTagsWithSuccess:(void(^)(NSArray *tags))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listTags:self.authenticationToken];
    } success:success failure:failure];
}

- (void)listTagsByNotebookWithGuid:(EDAMGuid)guid
                           success:(void(^)(NSArray *tags))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listTagsByNotebook:self.authenticationToken notebookGuid:guid];
    } success:success failure:failure];
};

- (void)getTagWithGuid:(EDAMGuid)guid
               success:(void(^)(EDAMTag *tag))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getTag:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)createTag:(EDAMTag *)tag
          success:(void(^)(EDAMTag *tag))success
          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client createTag:self.authenticationToken tag:tag];
    } success:success failure:failure];
}

- (void)updateTag:(EDAMTag *)tag
          success:(void(^)(int32_t usn))success
          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateTag:self.authenticationToken tag:tag];
    } success:success failure:failure];
}

- (void)untagAllWithGuid:(EDAMGuid)guid
                 success:(void(^)())success
                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^ {
        [self.client untagAll:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)expungeTagWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeTag:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore search methods

- (void)listSearchesWithSuccess:(void(^)(NSArray *searches))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listSearches:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getSearchWithGuid:(EDAMGuid)guid
                  success:(void(^)(EDAMSavedSearch *search))success
                  failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id {
        return [self.client getSearch:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)createSearch:(EDAMSavedSearch *)search
             success:(void(^)(EDAMSavedSearch *search))success
             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client createSearch:self.authenticationToken search:search];
    } success:success failure:failure];
}

- (void)updateSearch:(EDAMSavedSearch *)search
             success:(void(^)(int32_t usn))success
             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateSearch:self.authenticationToken search:search];
    } success:success failure:failure];
}

- (void)expungeSearchWithGuid:(EDAMGuid)guid
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeSearch:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore notes methods
- (void)findRelatedWithQuery:(EDAMRelatedQuery *)query
                  resultSpec:(EDAMRelatedResultSpec *)resultSpec
                     success:(void(^)(EDAMRelatedResult *result))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client findRelated:self.authenticationToken query:query resultSpec:resultSpec];
    } success:success failure:failure];
}

- (void)findNotesWithFilter:(EDAMNoteFilter *)filter
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                    success:(void(^)(EDAMNoteList *list))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client findNotes:self.authenticationToken filter:filter offset:offset maxNotes:maxNotes];
    } success:success failure:failure];
}

- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter
                            guid:(EDAMGuid)guid
                         success:(void(^)(int32_t offset))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client findNoteOffset:self.authenticationToken filter:filter guid:guid];
    } success:success failure:failure];
}

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset
                           maxNotes:(int32_t)maxNotes
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(EDAMNotesMetadataList *metadata))success
                            failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client findNotesMetadata:self.authenticationToken filter:filter offset:offset maxNotes:maxNotes resultSpec:resultSpec];
    } success:success failure:failure];
}

- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter
                       withTrash:(BOOL)withTrash
                         success:(void(^)(EDAMNoteCollectionCounts *counts))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client findNoteCounts:self.authenticationToken filter:filter withTrash:withTrash];
    } success:success failure:failure];
}

- (void)getNoteWithGuid:(EDAMGuid)guid
            withContent:(BOOL)withContent
      withResourcesData:(BOOL)withResourcesData
withResourcesRecognition:(BOOL)withResourcesRecognition
withResourcesAlternateData:(BOOL)withResourcesAlternateData
                success:(void(^)(EDAMNote *note))success
                failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNote:self.authenticationToken guid:guid withContent:withContent withResourcesData:withResourcesData withResourcesRecognition:withResourcesRecognition withResourcesAlternateData:withResourcesAlternateData];
    } success:success failure:failure];
}

- (void)getNoteApplicationDataWithGuid:(EDAMGuid)guid
                               success:(void(^)(EDAMLazyMap *map))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteApplicationData:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                    success:(void(^)(NSString *entry))success
                                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } success:success failure:failure];
}

- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                      value:(NSString *)value
                                    success:(void(^)(int32_t usn))success
                                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client setNoteApplicationDataEntry:self.authenticationToken guid:guid key:key value:value];
    } success:success failure:failure];
}

- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *) key
                                      success:(void(^)(int32_t usn))success
                                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client unsetNoteApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } success:success failure:failure];
}

- (void)getNoteContentWithGuid:(EDAMGuid)guid
                       success:(void(^)(NSString *content))success
                       failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteContent:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getNoteSearchTextWithGuid:(EDAMGuid)guid
                         noteOnly:(BOOL)noteOnly
              tokenizeForIndexing:(BOOL)tokenizeForIndexing
                          success:(void(^)(NSString *text))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteSearchText:self.authenticationToken guid:guid noteOnly:noteOnly tokenizeForIndexing:tokenizeForIndexing];
    } success:success failure:failure];
}

- (void)getResourceSearchTextWithGuid:(EDAMGuid)guid
                              success:(void(^)(NSString *text))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceSearchText:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getNoteTagNamesWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSArray *names))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteTagNames:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)createNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client createNote:self.authenticationToken note:note];
    } success:success failure:failure];
}

- (void)updateNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client updateNote:self.authenticationToken note:note];
    } success:success failure:failure];
}

- (void)deleteNoteWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client deleteNote:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)expungeNoteWithGuid:(EDAMGuid)guid
                    success:(void(^)(int32_t usn))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNote:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)expungeNotesWithGuids:(NSMutableArray *)guids
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNotes:self.authenticationToken noteGuids:guids];
    } success:success failure:failure];
}

- (void)expungeInactiveNoteWithSuccess:(void(^)(int32_t usn))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeInactiveNotes:self.authenticationToken];
    } success:success failure:failure];
}

- (void)copyNoteWithGuid:(EDAMGuid)guid
          toNoteBookGuid:(EDAMGuid)toNotebookGuid
                 success:(void(^)(EDAMNote *note))success
                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client copyNote:self.authenticationToken noteGuid:guid toNotebookGuid:toNotebookGuid];
    } success:success failure:failure];
}

- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                         success:(void(^)(NSArray *versions))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listNoteVersions:self.authenticationToken noteGuid:guid];
    } success:success failure:failure];
}

- (void)getNoteVersionWithGuid:(EDAMGuid)guid
             updateSequenceNum:(int32_t)updateSequenceNum
             withResourcesData:(BOOL)withResourcesData
      withResourcesRecognition:(BOOL)withResourcesRecognition
    withResourcesAlternateData:(BOOL)withResourcesAlternateData
                       success:(void(^)(EDAMNote *note))success
                       failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getNoteVersion:self.authenticationToken noteGuid:guid updateSequenceNum:updateSequenceNum withResourcesData:withResourcesData withResourcesRecognition:withResourcesRecognition withResourcesAlternateData:withResourcesAlternateData];
    } success:success failure:failure];
}

#pragma mark - NoteStore resource methods

- (void)getResourceWithGuid:(EDAMGuid)guid
                   withData:(BOOL)withData
            withRecognition:(BOOL)withRecognition
             withAttributes:(BOOL)withAttributes
          withAlternateDate:(BOOL)withAlternateData
                    success:(void(^)(EDAMResource *resource))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResource:self.authenticationToken guid:guid withData:withData withRecognition:withRecognition withAttributes:withAttributes withAlternateData:withAlternateData];
    } success:success failure:failure];
}

- (void)getResourceApplicationDataWithGuid:(EDAMGuid)guid
                                   success:(void(^)(EDAMLazyMap *map))success
                                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceApplicationData:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                        success:(void(^)(NSString *entry))success
                                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } success:success failure:failure];
}

- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                          value:(NSString *)value
                                        success:(void(^)(int32_t usn))success
                                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client setResourceApplicationDataEntry:self.authenticationToken guid:guid key:key value:value];
    } success:success failure:failure];
}

- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                          success:(void(^)(int32_t usn))success
                                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client unsetResourceApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } success:success failure:failure];
}

- (void)updateResource:(EDAMResource *)resource
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateResource:self.authenticationToken resource:resource];
    } success:success failure:failure];
}

- (void)getResourceDataWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSData *data))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceData:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getResourceByHashWithGuid:(EDAMGuid)guid
                      contentHash:(NSData *)contentHash
                         withData:(BOOL)withData
                  withRecognition:(BOOL)withRecognition
                withAlternateData:(BOOL)withAlternateData
                          success:(void(^)(EDAMResource *resource))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceByHash:self.authenticationToken noteGuid:guid contentHash:contentHash withData:withData withRecognition:withRecognition withAlternateData:withAlternateData];
    } success:success failure:failure];
}

- (void)getResourceRecognitionWithGuid:(EDAMGuid)guid
                               success:(void(^)(NSData *data))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceRecognition:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getResourceAlternateDataWithGuid:(EDAMGuid)guid
                                 success:(void(^)(NSData *data))success
                                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceAlternateData:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)getResourceAttributesWithGuid:(EDAMGuid)guid
                              success:(void(^)(EDAMResourceAttributes *attributes))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getResourceAttributes:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore shared notebook methods

- (void)getPublicNotebookWithUserID:(EDAMUserID)userId
                          publicUri:(NSString *)publicUri
                            success:(void(^)(EDAMNotebook *notebook))success
                            failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client getPublicNotebook:userId publicUri:publicUri];
    } success:success failure:failure];
}

- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                     failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id {
        return [self.client createSharedNotebook:self.authenticationToken sharedNotebook:sharedNotebook];
    } success:success failure:failure];
}

- (void)sendMessageToSharedNotebookMembersWithGuid:(EDAMGuid)guid
                                       messageText:(NSString *)messageText
                                        recipients:(NSMutableArray *)recipients
                                           success:(void(^)(int32_t numMessagesSent))success
                                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client sendMessageToSharedNotebookMembers:self.authenticationToken notebookGuid:guid messageText:messageText recipients:recipients];
    } success:success failure:failure];
}

- (void)listSharedNotebooksWithSuccess:(void(^)(NSArray *sharedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listSharedNotebooks:self.authenticationToken];
    } success:success failure:failure];
}

- (void)expungeSharedNotebooksWithIds:(NSMutableArray *)sharedNotebookIds
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeSharedNotebooks:self.authenticationToken sharedNotebookIds:sharedNotebookIds];
    } success:success failure:failure];
}

- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(EDAMLinkedNotebook *linkedNotebook))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client createLinkedNotebook:self.authenticationToken linkedNotebook:linkedNotebook];
    } success:success failure:failure];
}

- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateLinkedNotebook:self.authenticationToken linkedNotebook:linkedNotebook];
    } success:success failure:failure];
}

- (void)listLinkedNotebooksWithSuccess:(void(^)(NSArray *linkedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client listLinkedNotebooks:self.authenticationToken];
    } success:success failure:failure];
}

- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeLinkedNotebook:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)authenticateToSharedNotebook:(NSString *)shareKeyOrGlobalId
                             success:(void(^)(EDAMAuthenticationResult *result))success
                             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client authenticateToSharedNotebook:shareKeyOrGlobalId authenticationToken:self.authenticationToken];
    } success:success failure:failure];
}

- (void)getSharedNotebookByAuthWithSuccess:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                                   failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id {
        return [self.client getSharedNotebookByAuth:self.authenticationToken];
    } success:success failure:failure];
}

- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                        success:(void(^)())success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^ {
        [self.client emailNote:self.authenticationToken parameters:parameters];
    } success:success failure:failure];
}

- (void)shareNoteWithGuid:(EDAMGuid)guid
                  success:(void(^)(NSString *noteKey))success
                  failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client shareNote:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                        success:(void(^)())success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^ {
        [self.client stopSharingNote:self.authenticationToken guid:guid];
    } success:success failure:failure];
}

- (void)authenticateToSharedNoteWithGuid:(NSString *)guid
                                 noteKey:(NSString *)noteKey
                     authenticationToken:(NSString*)authenticationToken
                                 success:(void(^)(EDAMAuthenticationResult *result))success
                                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id {
        return [self.client authenticateToSharedNote:guid noteKey:noteKey authenticationToken:authenticationToken];
    } success:success failure:failure];
}

- (void)updateSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateSharedNotebook:self.authenticationToken sharedNotebook:sharedNotebook];
    } success:success failure:failure];
}

- (void) setSharedNotebookRecipientSettingsWithSharedNotebookId: (int64_t) sharedNotebookId
                                              recipientSettings: (EDAMSharedNotebookRecipientSettings *) recipientSettings
                                                        success:(void(^)(int32_t usn))success
                                                        failure:(void(^)(NSError *error))failure {
    [self invokeAsyncInt32Block:^int32_t{
        return [self.client setSharedNotebookRecipientSettings:self.authenticationToken sharedNotebookId:sharedNotebookId recipientSettings:recipientSettings];
    } success:success failure:failure];
}

- (void) cancelFirstOperation {
    [[self client] cancel];
}

#pragma mark - Protected routines

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                         maxResults:(NSUInteger)maxResults
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(NSArray *notesMetadataList))success
                            failure:(void(^)(NSError *error))failure
{
    [self findNotesMetadataInternalWithFilter:filter
                                       offset:0
                                   resultSpec:resultSpec
                                   maxResults:maxResults
                                      results:[[NSMutableArray alloc] init]
                                      success:success
                                      failure:failure];
}

- (void)findNotesMetadataInternalWithFilter:(EDAMNoteFilter *)filter
                                     offset:(int32_t)offset
                                 resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                                 maxResults:(NSUInteger)maxResults
                                    results:(NSMutableArray *)results
                                    success:(void(^)(NSArray *notesMetadataList))success
                                    failure:(void(^)(NSError *error))failure
{
    // If we've already fulfilled a bounded find order, then we are done.
    if (maxResults > 0 && results.count >= maxResults) {
        success(results);
        return;
    }
    
    // For this call, ask for the remaining number to fulfill the order, but don't exceed standard max.
    int32_t maxNotesThisCall = FIND_NOTES_DEFAULT_MAX_NOTES;
    if (maxResults > 0) {
        maxNotesThisCall = (int32_t)MIN(maxResults - results.count, (NSUInteger)maxNotesThisCall);
    }
    
    [self findNotesMetadataWithFilter:filter
                               offset:offset
                             maxNotes:maxNotesThisCall
                           resultSpec:resultSpec
                              success:^(EDAMNotesMetadataList *metadata) {
                                  // Add these results.
                                  [results addObjectsFromArray:metadata.notes];
                                  // Did we reach the total? (Use this formulation instead of checking against the results array length
                                  // because in theory the note count total could change between calls.
                                  int32_t nextIndex = [metadata.startIndex intValue] + (int32_t)metadata.notes.count;
                                  int32_t remainingCount = [metadata.totalNotes intValue] - nextIndex;
                                  // Go for another round if there are more to get.
                                  if (remainingCount > 0) {
                                      [self findNotesMetadataInternalWithFilter:filter
                                                                         offset:nextIndex
                                                                     resultSpec:resultSpec
                                                                     maxResults:maxResults
                                                                        results:results
                                                                        success:success
                                                                        failure:failure];
                                  } else {
                                      // Done.
                                      success(results);
                                  }
                              } failure:^(NSError *error) {
                                  failure(error);
                              }];
}

@end
