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
#if EN_PROGRESS_HANDLERS_ENABLED
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
#endif
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

- (void)fetchSyncStateWithCompletion:(void(^)(EDAMSyncState *syncState, NSError *error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getSyncState:self.authenticationToken];
    } completion:completion];
}

- (void)fetchSyncChunkAfterUSN:(int32_t)afterUSN
                    maxEntries:(int32_t)maxEntries
                  fullSyncOnly:(BOOL)fullSyncOnly
                    completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getSyncChunk:self.authenticationToken afterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly];
    } completion:completion];
}

- (void)fetchFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                            maxEntries:(int32_t)maxEntries
                                filter:(EDAMSyncChunkFilter *)filter
                            completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getFilteredSyncChunk:self.authenticationToken afterUSN:afterUSN maxEntries:maxEntries filter:filter];
    } completion:completion];
}

- (void)fetchSyncStateForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                             completion:(void(^)(EDAMSyncState *_Nullable syncState, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getLinkedNotebookSyncState:self.authenticationToken linkedNotebook:linkedNotebook];
    } completion:completion];
}

- (void)fetchSyncChunkForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                               afterUSN:(int32_t)afterUSN
                             maxEntries:(int32_t)maxEntries
                           fullSyncOnly:(BOOL)fullSyncOnly
                             completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getLinkedNotebookSyncChunk:self.authenticationToken linkedNotebook:linkedNotebook afterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly];
    } completion:completion];
}

#pragma mark - NoteStore notebook methods

- (void)listNotebooksWithCompletion:(void(^)(NSArray<EDAMNotebook *> *_Nullable notebooks, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listNotebooks:self.authenticationToken];
    } completion:completion];
}

- (void)fetchNotebookWithGuid:(EDAMGuid)guid
                   completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNotebook:self.authenticationToken guid:guid];
    } completion:completion];
}



- (void)fetchDefaultNotebookWithCompletion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getDefaultNotebook:self.authenticationToken];
    } completion:completion];
}

- (void)createNotebook:(EDAMNotebook *)notebook
            completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion
{
    [[ENSession sharedSession] listNotebooks_cleanCache];
    [self invokeAsyncObjectBlock:^id {
        return [self.client createNotebook:self.authenticationToken notebook:notebook];
    } completion:completion];
}

- (void)updateNotebook:(EDAMNotebook *)notebook
            completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateNotebook:self.authenticationToken notebook:notebook];
    } completion:completion];
}

- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                     completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNotebook:self.authenticationToken guid:guid];
    } completion:completion];
}

#pragma mark - NoteStore tags methods

- (void)listTagsWithCompletion:(void(^)(NSArray<EDAMTag *> *_Nullable tags, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listTags:self.authenticationToken];
    } completion:completion];
}

- (void)listTagsInNotebookWithGuid:(EDAMGuid)guid
                        completion:(void(^)(NSArray<EDAMTag *> * _Nullable tags, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listTagsByNotebook:self.authenticationToken notebookGuid:guid];
    } completion:completion];
};

- (void)fetchTagWithGuid:(EDAMGuid)guid
              completion:(void(^)(EDAMTag *_Nullable tag, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getTag:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)createTag:(EDAMTag *)tag
       completion:(void(^)(EDAMTag *_Nullable tag, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client createTag:self.authenticationToken tag:tag];
    } completion:completion];
}

- (void)updateTag:(EDAMTag *)tag
       completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateTag:self.authenticationToken tag:tag];
    } completion:completion];
}

- (void)untagAllWithGuid:(EDAMGuid)guid
              completion:(void(^)(NSError *error))completion
{
    [self invokeAsyncBlock:^ {
        [self.client untagAll:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)expungeTagWithGuid:(EDAMGuid)guid
                completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeTag:self.authenticationToken guid:guid];
    } completion:completion];
}

#pragma mark - NoteStore search methods

- (void)listSearchesWithCompletion:(void(^)(NSArray<EDAMSavedSearch *> *_Nullable searches, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listSearches:self.authenticationToken];
    } completion:completion];
}

- (void)fetchSearchWithGuid:(EDAMGuid)guid
                 completion:(void(^)(EDAMSavedSearch *_Nullable search, NSError *_Nullable error))completion

{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getSearch:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)createSearch:(EDAMSavedSearch *)search
          completion:(void(^)(EDAMSavedSearch *_Nullable search, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client createSearch:self.authenticationToken search:search];
    } completion:completion];
}

- (void)updateSearch:(EDAMSavedSearch *)search
          completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateSearch:self.authenticationToken search:search];
    } completion:completion];
}

- (void)expungeSearchWithGuid:(EDAMGuid)guid
                   completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeSearch:self.authenticationToken guid:guid];
    } completion:completion];
}

#pragma mark - NoteStore notes methods
- (void)findRelatedWithQuery:(EDAMRelatedQuery *)query
                  resultSpec:(EDAMRelatedResultSpec *)resultSpec
                  completion:(void(^)(EDAMRelatedResult *_Nullable result, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client findRelated:self.authenticationToken query:query resultSpec:resultSpec];
    } completion:completion];
}

- (void)findNotesWithFilter:(EDAMNoteFilter *)filter
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                 completion:(void(^)(EDAMNoteList *_Nullable list, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client findNotes:self.authenticationToken filter:filter offset:offset maxNotes:maxNotes];
    } completion:completion];
}

- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter
                            guid:(EDAMGuid)guid
                      completion:(void(^)(int32_t offset , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client findNoteOffset:self.authenticationToken filter:filter guid:guid];
    } completion:completion];
}

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset
                           maxNotes:(int32_t)maxNotes
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                         completion:(void(^)(EDAMNotesMetadataList *_Nullable metadata, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client findNotesMetadata:self.authenticationToken filter:filter offset:offset maxNotes:maxNotes resultSpec:resultSpec];
    } completion:completion];
}

- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter
                  includingTrash:(BOOL)includingTrash
                      completion:(void(^)(EDAMNoteCollectionCounts *_Nullable counts, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client findNoteCounts:self.authenticationToken filter:filter withTrash:includingTrash];
    } completion:completion];
}

- (void)fetchNoteWithGuid:(EDAMGuid)guid
         includingContent:(BOOL)includingContent
          resourceOptions:(ENResourceFetchOption)resourceOptions
               completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNote:self.authenticationToken
                               guid:guid
                        withContent:includingContent
                  withResourcesData:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeData)
           withResourcesRecognition:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeRecognitionData)
         withResourcesAlternateData:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeAlternateData)];
    } completion:completion];
}

- (void)fetchNoteApplicationDataWithGuid:(EDAMGuid)guid
                              completion:(void(^)(EDAMLazyMap *_Nullable map, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteApplicationData:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *)key
                                   completion:(void(^)(NSString *_Nullable entry, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } completion:completion];
}

- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                      value:(NSString *)value
                                 completion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client setNoteApplicationDataEntry:self.authenticationToken guid:guid key:key value:value];
    } completion:completion];
}

- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *) key
                                   completion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client unsetNoteApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } completion:completion];
}

- (void)fetchNoteContentWithGuid:(EDAMGuid)guid
                      completion:(void(^)(NSString *_Nullable content, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteContent:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchSearchTextForNoteWithGuid:(EDAMGuid)guid
                              noteOnly:(BOOL)noteOnly
                   tokenizeForIndexing:(BOOL)tokenizeForIndexing
                            completion:(void(^)(NSString *_Nullable text, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteSearchText:self.authenticationToken guid:guid noteOnly:noteOnly tokenizeForIndexing:tokenizeForIndexing];
    } completion:completion];
}

- (void)fetchSearchTextForResourceWithGuid:(EDAMGuid)guid
                                completion:(void(^)(NSString *_Nullable text, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceSearchText:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchTagNamesForNoteWithGuid:(EDAMGuid)guid
                          completion:(void(^)(NSArray<NSString *> *_Nullable names, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteTagNames:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)createNote:(EDAMNote *)note
        completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client createNote:self.authenticationToken note:note];
    } completion:completion];
}

- (void)updateNote:(EDAMNote *)note
        completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client updateNote:self.authenticationToken note:note];
    } completion:completion];
}

- (void)deleteNoteWithGuid:(EDAMGuid)guid
                completion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client deleteNote:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)expungeNoteWithGuid:(EDAMGuid)guid
                 completion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNote:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)expungeNotesWithGuids:(NSArray<EDAMGuid> *)guids
                   completion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeNotes:self.authenticationToken noteGuids:guids];
    } completion:completion];
}

- (void)expungeInactiveNoteWithCompletion:(void(^)(int32_t usn, NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeInactiveNotes:self.authenticationToken];
    } completion:completion];
}

- (void)copyNoteWithGuid:(EDAMGuid)guid
      toNotebookWithGuid:(EDAMGuid)notebookGuid
              completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client copyNote:self.authenticationToken noteGuid:guid toNotebookGuid:notebookGuid];
    } completion:completion];
}

- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                      completion:(void(^)(NSArray<EDAMNoteVersionId *> *_Nullable versions, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listNoteVersions:self.authenticationToken noteGuid:guid];
    } completion:completion];
}

- (void)fetchNoteVersionWithGuid:(EDAMGuid)guid
               updateSequenceNum:(int32_t)updateSequenceNum
                 resourceOptions:(ENResourceFetchOption)resourceOptions
                      completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getNoteVersion:self.authenticationToken
                                  noteGuid:guid
                         updateSequenceNum:updateSequenceNum
                         withResourcesData:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeData)
                  withResourcesRecognition:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeRecognitionData)
                withResourcesAlternateData:EN_FLAG_ISSET(resourceOptions, ENResourceFetchOptionIncludeAlternateData)];
    } completion:completion];
}

#pragma mark - NoteStore resource methods

- (void)fetchResourceWithGuid:(EDAMGuid)guid
                      options:(ENResourceFetchOption)options
                   completion:(void(^)(EDAMResource *_Nullable resource, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResource:self.authenticationToken
                                   guid:guid
                               withData:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeData)
                        withRecognition:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeRecognitionData)
                         withAttributes:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeAttributes)
                      withAlternateData:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeAlternateData)];
    } completion:completion];
}

- (void)fetchResourceApplicationDataWithGuid:(EDAMGuid)guid
                                  completion:(void(^)(EDAMLazyMap *_Nullable map, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceApplicationData:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                       completion:(void(^)(NSString *_Nullable entry, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } completion:completion];
}

- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                          value:(NSString *)value
                                     completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client setResourceApplicationDataEntry:self.authenticationToken guid:guid key:key value:value];
    } completion:completion];
}

- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                       completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client unsetResourceApplicationDataEntry:self.authenticationToken guid:guid key:key];
    } completion:completion];
}

- (void)updateResource:(EDAMResource *)resource
            completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateResource:self.authenticationToken resource:resource];
    } completion:completion];
}

- (void)fetchResourceDataWithGuid:(EDAMGuid)guid
                       completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceData:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchResourceByHashWithGuid:(EDAMGuid)guid
                        contentHash:(NSData *)contentHash
                            options:(ENResourceFetchOption)options
                         completion:(void(^)(EDAMResource *_Nullable resource, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceByHash:self.authenticationToken
                                     noteGuid:guid
                                  contentHash:contentHash
                                     withData:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeData)
                              withRecognition:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeRecognitionData)
                            withAlternateData:EN_FLAG_ISSET(options, ENResourceFetchOptionIncludeAlternateData)];
    } completion:completion];
}

- (void)fetchRecognitionDataForResourceWithGuid:(EDAMGuid)guid
                                     completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceRecognition:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchAlternateDataForResourceWithGuid:(EDAMGuid)guid
                                   completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceAlternateData:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)fetchAttributesForResourceWithGuid:(EDAMGuid)guid
                                completion:(void(^)(EDAMResourceAttributes *_Nullable attributes, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getResourceAttributes:self.authenticationToken guid:guid];
    } completion:completion];
}

#pragma mark - NoteStore shared notebook methods

- (void)fetchPublicNotebookWithUserID:(EDAMUserID)userId
                            publicURI:(NSString *)publicURI
                           completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getPublicNotebook:userId publicUri:publicURI];
    } completion:completion];
}

- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                  completion:(void(^)(EDAMSharedNotebook *_Nullable sharedNotebook, NSError *_Nullable error))completion

{
    [self invokeAsyncObjectBlock:^id {
        return [self.client createSharedNotebook:self.authenticationToken sharedNotebook:sharedNotebook];
    } completion:completion];
}

- (void)sendMessageToMembersOfSharedNotebookWithGuid:(EDAMGuid)guid
                                         messageText:(NSString *)messageText
                                          recipients:(NSArray<NSString *> *)recipients
                                          completion:(void(^)(int32_t numMessagesSent , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client sendMessageToSharedNotebookMembers:self.authenticationToken notebookGuid:guid messageText:messageText recipients:recipients];
    } completion:completion];
}

- (void)listSharedNotebooksWithCompletion:(void(^)(NSArray<EDAMSharedNotebook *> *_Nullable sharedNotebooks, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listSharedNotebooks:self.authenticationToken];
    } completion:completion];
}

- (void)expungeSharedNotebooksWithIds:(NSArray<NSNumber *> *)sharedNotebookIds
                           completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeSharedNotebooks:self.authenticationToken sharedNotebookIds:sharedNotebookIds];
    } completion:completion];
}

- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                  completion:(void(^)(EDAMLinkedNotebook *_Nullable linkedNotebook, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client createLinkedNotebook:self.authenticationToken linkedNotebook:linkedNotebook];
    } completion:completion];
}

- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateLinkedNotebook:self.authenticationToken linkedNotebook:linkedNotebook];
    } completion:completion];
}

- (void)listLinkedNotebooksWithCompletion:(void(^)(NSArray<EDAMLinkedNotebook *> *_Nullable linkedNotebooks, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client listLinkedNotebooks:self.authenticationToken];
    } completion:completion];
}

- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                           completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client expungeLinkedNotebook:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)authenticateToSharedNotebook:(NSString *)shareKeyOrGlobalId
                          completion:(void(^)(EDAMAuthenticationResult *_Nullable result, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client authenticateToSharedNotebook:shareKeyOrGlobalId authenticationToken:self.authenticationToken];
    } completion:completion];
}

- (void)fetchSharedNotebookByAuthWithCompletion:(void(^)(EDAMSharedNotebook *_Nullable sharedNotebook, NSError *_Nullable error))completion;
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client getSharedNotebookByAuth:self.authenticationToken];
    } completion:completion];
}

- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                     completion:(void(^)(NSError *error))completion
{
    [self invokeAsyncBlock:^ {
        [self.client emailNote:self.authenticationToken parameters:parameters];
    } completion:completion];
}

- (void)shareNoteWithGuid:(EDAMGuid)guid
               completion:(void(^)(NSString *_Nullable noteKey, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client shareNote:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                     completion:(void(^)(NSError *error))completion
{
    [self invokeAsyncBlock:^ {
        [self.client stopSharingNote:self.authenticationToken guid:guid];
    } completion:completion];
}

- (void)authenticateToSharedNoteWithGuid:(NSString *)guid
                                 noteKey:(NSString *)noteKey
                     authenticationToken:(nullable NSString*)authenticationToken
                              completion:(void(^)(EDAMAuthenticationResult *_Nullable result, NSError *_Nullable error))completion
{
    [self invokeAsyncObjectBlock:^id {
        return [self.client authenticateToSharedNote:guid noteKey:noteKey authenticationToken:authenticationToken];
    } completion:completion];
}

- (void)updateSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion
{
    [self invokeAsyncInt32Block:^int32_t {
        return [self.client updateSharedNotebook:self.authenticationToken sharedNotebook:sharedNotebook];
    } completion:completion];
}

- (void)setRecipientSettings:(EDAMSharedNotebookRecipientSettings *) recipientSettings
     forSharedNotebookWithID:(int64_t)sharedNotebookId
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion {
    [self invokeAsyncInt32Block:^int32_t{
        return [self.client setSharedNotebookRecipientSettings:self.authenticationToken sharedNotebookId:sharedNotebookId recipientSettings:recipientSettings];
    } completion:completion];
}

- (void) cancelFirstOperation {
    [[self client] cancel];
}



#pragma mark - Protected routines

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                         maxResults:(NSUInteger)maxResults
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(NSArray<EDAMNoteMetadata *> *notesMetadataList))success
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
                                    results:(NSMutableArray<EDAMNoteMetadata *> *)results
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
                           completion:^(EDAMNotesMetadataList * _Nullable metadata, NSError * _Nullable error) {
                               if (error) {
                                   failure(error);
                                   return;
                               }
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
                           }];
}







#pragma mark - Deprecated

- (void)getSyncStateWithSuccess:(void(^)(EDAMSyncState *syncState))success
                        failure:(void(^)(NSError *error))failure
{
    [self fetchSyncStateWithCompletion:^(EDAMSyncState * _Nullable syncState, NSError * _Nullable error) {
        (error == nil) ? success(syncState) : failure(error);
    }];
}

- (void)getSyncChunkAfterUSN:(int32_t)afterUSN
                  maxEntries:(int32_t)maxEntries
                fullSyncOnly:(BOOL)fullSyncOnly
                     success:(void(^)(EDAMSyncChunk *syncChunk))success
                     failure:(void(^)(NSError *error))failure
{
    [self fetchSyncChunkAfterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly completion:^(EDAMSyncChunk * _Nullable syncChunk, NSError * _Nullable error) {
        (error == nil) ? success(syncChunk) : failure(error);
    }];
}

- (void)getFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                          maxEntries:(int32_t)maxEntries
                              filter:(EDAMSyncChunkFilter *)filter
                             success:(void(^)(EDAMSyncChunk *syncChunk))success
                             failure:(void(^)(NSError *error))failure
{
    [self fetchFilteredSyncChunkAfterUSN:afterUSN maxEntries:maxEntries filter:filter completion:^(EDAMSyncChunk * _Nullable syncChunk, NSError * _Nullable error) {
        (error == nil) ? success(syncChunk) : failure(error);
    }];
}

- (void)getLinkedNotebookSyncState:(EDAMLinkedNotebook *)linkedNotebook
                           success:(void(^)(EDAMSyncState *syncState))success
                           failure:(void(^)(NSError *error))failure
{
    [self fetchSyncStateForLinkedNotebook:linkedNotebook completion:^(EDAMSyncState * _Nullable syncState, NSError * _Nullable error) {
        (error == nil) ? success(syncState) : failure(error);
    }];
}

- (void)getLinkedNotebookSyncChunk:(EDAMLinkedNotebook *)linkedNotebook
                          afterUSN:(int32_t)afterUSN
                        maxEntries:(int32_t)maxEntries
                      fullSyncOnly:(BOOL)fullSyncOnly
                           success:(void(^)(EDAMSyncChunk *syncChunk))success
                           failure:(void(^)(NSError *error))failure
{
    [self fetchSyncChunkForLinkedNotebook:linkedNotebook afterUSN:afterUSN maxEntries:maxEntries fullSyncOnly:fullSyncOnly completion:^(EDAMSyncChunk * _Nullable syncChunk, NSError * _Nullable error) {
        (error == nil) ? success(syncChunk) : failure(error);
    }];
}

- (void)listNotebooksWithSuccess:(void(^)(NSArray<EDAMNotebook *> *notebooks))success
                         failure:(void(^)(NSError *error))failure
{
    [self listNotebooksWithCompletion:^(NSArray<EDAMNotebook *> * _Nullable notebooks, NSError * _Nullable error) {
        (error == nil) ? success(notebooks) : failure(error);
    }];
}

- (void)getNotebookWithGuid:(EDAMGuid)guid
                    success:(void(^)(EDAMNotebook *notebook))success
                    failure:(void(^)(NSError *error))failure
{
    [self fetchNotebookWithGuid:guid completion:^(EDAMNotebook * _Nullable notebook, NSError * _Nullable error) {
        (error == nil) ? success(notebook) : failure(error);
    }];
}

- (void)getDefaultNotebookWithSuccess:(void(^)(EDAMNotebook *notebook))success
                              failure:(void(^)(NSError *error))failure
{
    [self fetchDefaultNotebookWithCompletion:^(EDAMNotebook * _Nullable notebook, NSError * _Nullable error) {
        (error == nil) ? success(notebook) : failure(error);
    }];
}

- (void)createNotebook:(EDAMNotebook *)notebook
               success:(void(^)(EDAMNotebook *notebook))success
               failure:(void(^)(NSError *error))failure
{
    [self createNotebook:notebook completion:^(EDAMNotebook * _Nullable createdNotebook, NSError * _Nullable error) {
        (error == nil) ? success(createdNotebook) : failure(error);
    }];
}

- (void)updateNotebook:(EDAMNotebook *)notebook
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self updateNotebook:notebook completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                        success:(void(^)(int32_t usn))success
                        failure:(void(^)(NSError *error))failure
{
    [self expungeNotebookWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)listTagsWithSuccess:(void(^)(NSArray<EDAMTag *> *tags))success
                    failure:(void(^)(NSError *error))failure
{
    [self listTagsWithCompletion:^(NSArray<EDAMTag *> * _Nullable tags, NSError * _Nullable error) {
        (error == nil) ? success(tags) : failure(error);
    }];
}

- (void)listTagsByNotebookWithGuid:(EDAMGuid)guid
                           success:(void(^)(NSArray<EDAMTag *> *tags))success
                           failure:(void(^)(NSError *error))failure
{
    [self listTagsInNotebookWithGuid:guid completion:^(NSArray<EDAMTag *> *_Nullable tags, NSError * _Nullable error) {
        (error == nil) ? success(tags) : failure(error);
    }];
}

- (void)getTagWithGuid:(EDAMGuid)guid
               success:(void(^)(EDAMTag *tag))success
               failure:(void(^)(NSError *error))failure
{
    [self fetchTagWithGuid:guid completion:^(EDAMTag * _Nullable tag, NSError * _Nullable error) {
        (error == nil) ? success(tag) : failure(error);
    }];
}

- (void)createTag:(EDAMTag *)tag
          success:(void(^)(EDAMTag *tag))success
          failure:(void(^)(NSError *error))failure
{
    [self createTag:tag completion:^(EDAMTag * _Nullable createdTag, NSError * _Nullable error) {
        (error == nil) ? success(createdTag) : failure(error);
    }];
}

- (void)updateTag:(EDAMTag *)tag
          success:(void(^)(int32_t usn))success
          failure:(void(^)(NSError *error))failure
{
    [self updateTag:tag completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)untagAllWithGuid:(EDAMGuid)guid
                 success:(void(^)(void))success
                 failure:(void(^)(NSError *error))failure
{
    [self untagAllWithGuid:guid completion:^(NSError * _Nonnull error) {
        (error == nil) ? success() : failure(error);
    }];
}

- (void)expungeTagWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self expungeTagWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)listSearchesWithSuccess:(void(^)(NSArray<EDAMSavedSearch *> *searches))success
                        failure:(void(^)(NSError *error))failure
{
    [self listSearchesWithCompletion:^(NSArray<EDAMSavedSearch *> * _Nullable searches, NSError * _Nullable error) {
        (error == nil) ? success(searches) : failure(error);
    }];
}

- (void)getSearchWithGuid:(EDAMGuid)guid
                  success:(void(^)(EDAMSavedSearch *search))success
                  failure:(void(^)(NSError *error))failure
{
    [self fetchSearchWithGuid:guid completion:^(EDAMSavedSearch * _Nullable search, NSError * _Nullable error) {
        (error == nil) ? success(search) : failure(error);
    }];
}

- (void)createSearch:(EDAMSavedSearch *)search
             success:(void(^)(EDAMSavedSearch *search))success
             failure:(void(^)(NSError *error))failure
{
    [self createSearch:search completion:^(EDAMSavedSearch * _Nullable createdSearch, NSError * _Nullable error) {
        (error == nil) ? success(createdSearch) : failure(error);
    }];
}

- (void)updateSearch:(EDAMSavedSearch *)search
             success:(void(^)(int32_t usn))success
             failure:(void(^)(NSError *error))failure
{
    [self updateSearch:search completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)expungeSearchWithGuid:(EDAMGuid)guid
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self expungeSearchWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)findRelatedWithQuery:(EDAMRelatedQuery *)query
                  resultSpec:(EDAMRelatedResultSpec *)resultSpec
                     success:(void(^)(EDAMRelatedResult *result))success
                     failure:(void(^)(NSError *error))failure
{
    [self findRelatedWithQuery:query resultSpec:resultSpec completion:^(EDAMRelatedResult * _Nullable result, NSError * _Nullable error) {
        (error == nil) ? success(result) : failure(error);
    }];
}

- (void)findNotesWithFilter:(EDAMNoteFilter *)filter
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                    success:(void(^)(EDAMNoteList *list))success
                    failure:(void(^)(NSError *error))failure
{
    [self findNotesWithFilter:filter offset:offset maxNotes:maxNotes completion:^(EDAMNoteList * _Nullable list, NSError * _Nullable error) {
        (error == nil) ? success(list) : failure(error);
    }];
}

- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter
                            guid:(EDAMGuid)guid
                         success:(void(^)(int32_t offset))success
                         failure:(void(^)(NSError *error))failure
{
    [self findNoteOffsetWithFilter:filter guid:guid completion:^(int32_t offset, NSError * _Nullable error) {
        (error == nil) ? success(offset) : failure(error);
    }];
}

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset
                           maxNotes:(int32_t)maxNotes
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(EDAMNotesMetadataList *metadata))success
                            failure:(void(^)(NSError *error))failure
{
    [self findNotesMetadataWithFilter:filter offset:offset maxNotes:maxNotes resultSpec:resultSpec completion:^(EDAMNotesMetadataList * _Nullable metadata, NSError * _Nullable error) {
        (error == nil) ? success(metadata) : failure(error);
    }];
}


- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter
                       withTrash:(BOOL)withTrash
                         success:(void(^)(EDAMNoteCollectionCounts *counts))success
                         failure:(void(^)(NSError *error))failure
{
    [self findNoteCountsWithFilter:filter includingTrash:withTrash completion:^(EDAMNoteCollectionCounts * _Nullable counts, NSError * _Nullable error) {
        (error == nil) ? success(counts) : failure(error);
    }];
}

- (void)getNoteWithGuid:(EDAMGuid)guid
            withContent:(BOOL)withContent
      withResourcesData:(BOOL)withResourcesData
withResourcesRecognition:(BOOL)withResourcesRecognition
withResourcesAlternateData:(BOOL)withResourcesAlternateData
                success:(void(^)(EDAMNote *note))success
                failure:(void(^)(NSError *error))failure
{
    ENResourceFetchOption options = 0;
    if (withResourcesData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeData);
    }
    if (withResourcesRecognition) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeRecognitionData);
    }
    if (withResourcesAlternateData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeAlternateData);
    }
    [self fetchNoteWithGuid:guid includingContent:withContent resourceOptions:options completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
        (error == nil) ? success(note) : failure(error);
    }];
}

- (void)getNoteApplicationDataWithGuid:(EDAMGuid)guid
                               success:(void(^)(EDAMLazyMap *map))success
                               failure:(void(^)(NSError *error))failure
{
    [self fetchNoteApplicationDataWithGuid:guid completion:^(EDAMLazyMap * _Nullable map, NSError * _Nullable error) {
        (error == nil) ? success(map) : failure(error);
    }];
}

- (void)getNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                    success:(void(^)(NSString *entry))success
                                    failure:(void(^)(NSError *error))failure
{
    [self fetchNoteApplicationDataEntryWithGuid:guid key:key completion:^(NSString * _Nullable entry, NSError * _Nullable error) {
        (error == nil) ? success(entry) : failure(error);
    }];
}

- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                      value:(NSString *)value
                                    success:(void(^)(int32_t usn))success
                                    failure:(void(^)(NSError *error))failure
{
    [self setNoteApplicationDataEntryWithGuid:guid key:key value:value completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *) key
                                      success:(void(^)(int32_t usn))success
                                      failure:(void(^)(NSError *error))failure
{
    [self unsetNoteApplicationDataEntryWithGuid:guid key:key completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)getNoteContentWithGuid:(EDAMGuid)guid
                       success:(void(^)(NSString *content))success
                       failure:(void(^)(NSError *error))failure
{
    [self fetchNoteContentWithGuid:guid completion:^(NSString * _Nullable content, NSError * _Nullable error) {
        (error == nil) ? success(content) : failure(error);
    }];
}

- (void)getNoteSearchTextWithGuid:(EDAMGuid)guid
                         noteOnly:(BOOL)noteOnly
              tokenizeForIndexing:(BOOL)tokenizeForIndexing
                          success:(void(^)(NSString *text))success
                          failure:(void(^)(NSError *error))failure
{
    [self fetchSearchTextForNoteWithGuid:guid noteOnly:noteOnly tokenizeForIndexing:tokenizeForIndexing completion:^(NSString * _Nullable text, NSError * _Nullable error) {
        (error == nil) ? success(text) : failure(error);
    }];
}

- (void)getResourceSearchTextWithGuid:(EDAMGuid)guid
                              success:(void(^)(NSString *text))success
                              failure:(void(^)(NSError *error))failure
{
    [self fetchSearchTextForResourceWithGuid:guid completion:^(NSString * _Nullable text, NSError * _Nullable error) {
        (error == nil) ? success(text) : failure(error);
    }];
}

- (void)getNoteTagNamesWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSArray<NSString *> *names))success
                        failure:(void(^)(NSError *error))failure
{
    [self fetchTagNamesForNoteWithGuid:guid completion:^(NSArray<NSString *> * _Nullable names, NSError * _Nullable error) {
        (error == nil) ? success(names) : failure(error);
    }];
}

- (void)createNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
{
    [self createNote:note completion:^(EDAMNote * _Nullable createdNote, NSError * _Nullable error) {
        (error == nil) ? success(createdNote) : failure(error);
    }];
}

- (void)updateNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
{
    [self updateNote:note completion:^(EDAMNote * _Nullable updatedNote, NSError * _Nullable error) {
        (error == nil) ? success(updatedNote) : failure(error);
    }];
}

- (void)deleteNoteWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self deleteNoteWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)expungeNoteWithGuid:(EDAMGuid)guid
                    success:(void(^)(int32_t usn))success
                    failure:(void(^)(NSError *error))failure
{
    [self expungeNoteWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)expungeNotesWithGuids:(NSArray<EDAMGuid> *)guids
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self expungeNotesWithGuids:guids completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)expungeInactiveNoteWithSuccess:(void(^)(int32_t usn))success
                               failure:(void(^)(NSError *error))failure
{
    [self expungeInactiveNoteWithCompletion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)copyNoteWithGuid:(EDAMGuid)guid
          toNoteBookGuid:(EDAMGuid)toNotebookGuid
                 success:(void(^)(EDAMNote *note))success
                 failure:(void(^)(NSError *error))failure
{
    [self copyNoteWithGuid:guid toNotebookWithGuid:toNotebookGuid completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
        (error == nil) ? success(note) : failure(error);
    }];
}

- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                         success:(void(^)(NSArray<EDAMNoteVersionId *> *versions))success
                         failure:(void(^)(NSError *error))failure
{
    [self listNoteVersionsWithGuid:guid completion:^(NSArray<EDAMNoteVersionId *> * _Nullable versions, NSError * _Nullable error) {
        (error == nil) ? success(versions) : failure(error);
    }];
}

- (void)getNoteVersionWithGuid:(EDAMGuid)guid
             updateSequenceNum:(int32_t)updateSequenceNum
             withResourcesData:(BOOL)withResourcesData
      withResourcesRecognition:(BOOL)withResourcesRecognition
    withResourcesAlternateData:(BOOL)withResourcesAlternateData
                       success:(void(^)(EDAMNote *note))success
                       failure:(void(^)(NSError *error))failure
{
    ENResourceFetchOption options = 0;
    if (withResourcesData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeData);
    }
    if (withResourcesRecognition) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeRecognitionData);
    }
    if (withResourcesAlternateData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeAlternateData);
    }
    [self fetchNoteVersionWithGuid:guid updateSequenceNum:updateSequenceNum resourceOptions:options completion:^(EDAMNote * _Nullable note, NSError * _Nullable error) {
        (error == nil) ? success(note) : failure(error);
    }];
}


- (void)getResourceWithGuid:(EDAMGuid)guid
                   withData:(BOOL)withData
            withRecognition:(BOOL)withRecognition
             withAttributes:(BOOL)withAttributes
          withAlternateDate:(BOOL)withAlternateData
                    success:(void(^)(EDAMResource *resource))success
                    failure:(void(^)(NSError *error))failure
{
    ENResourceFetchOption options = 0;
    if (withData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeData);
    }
    if (withRecognition) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeRecognitionData);
    }
    if (withAlternateData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeAlternateData);
    }
    if (withAttributes) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeAttributes);
    }
    [self fetchResourceWithGuid:guid options:options completion:^(EDAMResource * _Nullable resource, NSError * _Nullable error) {
        (error == nil) ? success(resource) : failure(error);
    }];
}

- (void)getResourceApplicationDataWithGuid:(EDAMGuid)guid
                                   success:(void(^)(EDAMLazyMap *map))success
                                   failure:(void(^)(NSError *error))failure
{
    [self fetchResourceApplicationDataWithGuid:guid completion:^(EDAMLazyMap * _Nullable map, NSError * _Nullable error) {
        (error == nil) ? success(map) : failure(error);
    }];
}

- (void)getResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                        success:(void(^)(NSString *entry))success
                                        failure:(void(^)(NSError *error))failure
{
    [self fetchResourceApplicationDataEntryWithGuid:guid key:key completion:^(NSString * _Nullable entry, NSError * _Nullable error) {
        (error == nil) ? success(entry) : failure(error);
    }];
}

- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                          value:(NSString *)value
                                        success:(void(^)(int32_t usn))success
                                        failure:(void(^)(NSError *error))failure
{
    [self setResourceApplicationDataEntryWithGuid:guid key:key value:value completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                          success:(void(^)(int32_t usn))success
                                          failure:(void(^)(NSError *error))failure
{
    [self unsetResourceApplicationDataEntryWithGuid:guid key:key completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)updateResource:(EDAMResource *)resource
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self updateResource:resource completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)getResourceDataWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSData *data))success
                        failure:(void(^)(NSError *error))failure
{
    [self fetchResourceDataWithGuid:guid completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        (error == nil) ? success(data) : failure(error);
    }];
}

- (void)getResourceByHashWithGuid:(EDAMGuid)guid
                      contentHash:(NSData *)contentHash
                         withData:(BOOL)withData
                  withRecognition:(BOOL)withRecognition
                withAlternateData:(BOOL)withAlternateData
                          success:(void(^)(EDAMResource *resource))success
                          failure:(void(^)(NSError *error))failure
{
    ENResourceFetchOption options = 0;
    if (withData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeData);
    }
    if (withRecognition) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeRecognitionData);
    }
    if (withAlternateData) {
        EN_FLAG_SET(options, ENResourceFetchOptionIncludeAlternateData);
    }
    [self fetchResourceByHashWithGuid:guid contentHash:contentHash options:options completion:^(EDAMResource * _Nullable resource, NSError * _Nullable error) {
        (error == nil) ? success(resource) : failure(error);
    }];
}

- (void)getResourceRecognitionWithGuid:(EDAMGuid)guid
                               success:(void(^)(NSData *data))success
                               failure:(void(^)(NSError *error))failure
{
    [self fetchRecognitionDataForResourceWithGuid:guid completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        (error == nil) ? success(data) : failure(error);
    }];
}

- (void)getResourceAlternateDataWithGuid:(EDAMGuid)guid
                                 success:(void(^)(NSData *data))success
                                 failure:(void(^)(NSError *error))failure
{
    [self fetchAlternateDataForResourceWithGuid:guid completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        (error == nil) ? success(data) : failure(error);
    }];
}

- (void)getResourceAttributesWithGuid:(EDAMGuid)guid
                              success:(void(^)(EDAMResourceAttributes *attributes))success
                              failure:(void(^)(NSError *error))failure
{
    [self fetchAttributesForResourceWithGuid:guid completion:^(EDAMResourceAttributes * _Nullable attributes, NSError * _Nullable error) {
        (error == nil) ? success(attributes) : failure(error);
    }];
}

- (void)getPublicNotebookWithUserID:(EDAMUserID)userId
                          publicUri:(NSString *)publicUri
                            success:(void(^)(EDAMNotebook *notebook))success
                            failure:(void(^)(NSError *error))failure
{
    [self fetchPublicNotebookWithUserID:userId publicURI:publicUri completion:^(EDAMNotebook * _Nullable notebook, NSError * _Nullable error) {
        (error == nil) ? success(notebook) : failure(error);
    }];
}

- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                     failure:(void(^)(NSError *error))failure
{
    [self createSharedNotebook:sharedNotebook completion:^(EDAMSharedNotebook * _Nullable createdSharedNotebook, NSError * _Nullable error) {
        (error == nil) ? success(createdSharedNotebook) : failure(error);
    }];
}

- (void)sendMessageToSharedNotebookMembersWithGuid:(EDAMGuid)guid
                                       messageText:(NSString *)messageText
                                        recipients:(NSArray<NSString *> *)recipients
                                           success:(void(^)(int32_t numMessagesSent))success
                                           failure:(void(^)(NSError *error))failure
{
    [self sendMessageToMembersOfSharedNotebookWithGuid:guid messageText:messageText recipients:recipients completion:^(int32_t numMessagesSent, NSError * _Nullable error) {
        (error == nil) ? success(numMessagesSent) : failure(error);
    }];
}

- (void)listSharedNotebooksWithSuccess:(void(^)(NSArray<EDAMSharedNotebook *> *sharedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self listSharedNotebooksWithCompletion:^(NSArray<EDAMSharedNotebook *> * _Nullable sharedNotebooks, NSError * _Nullable error) {
        (error == nil) ? success(sharedNotebooks) : failure(error);
    }];
}

- (void)expungeSharedNotebooksWithIds:(NSArray<NSNumber *> *)sharedNotebookIds
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self expungeSharedNotebooksWithIds:sharedNotebookIds completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(EDAMLinkedNotebook *linkedNotebook))success
                     failure:(void(^)(NSError *error))failure
{
    [self createLinkedNotebook:linkedNotebook completion:^(EDAMLinkedNotebook * _Nullable createdLinkedNotebook, NSError * _Nullable error) {
        (error == nil) ? success(createdLinkedNotebook) : failure(error);
    }];
}

- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
{
    [self updateLinkedNotebook:linkedNotebook completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)listLinkedNotebooksWithSuccess:(void(^)(NSArray<EDAMLinkedNotebook *> *linkedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self listLinkedNotebooksWithCompletion:^(NSArray<EDAMLinkedNotebook *> * _Nullable linkedNotebooks, NSError * _Nullable error) {
        (error == nil) ? success(linkedNotebooks) : failure(error);
    }];
}

- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self expungeLinkedNotebookWithGuid:guid completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void)authenticateToSharedNotebook:(NSString *)shareKeyOrGlobalId
                             success:(void(^)(EDAMAuthenticationResult *result))success
                             failure:(void(^)(NSError *error))failure
{
    [self authenticateToSharedNotebook:shareKeyOrGlobalId completion:^(EDAMAuthenticationResult * _Nullable result, NSError * _Nullable error) {
        (error == nil) ? success(result) : failure(error);
    }];
}

- (void)getSharedNotebookByAuthWithSuccess:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                                   failure:(void(^)(NSError *error))failure
{
    [self fetchSharedNotebookByAuthWithCompletion:^(EDAMSharedNotebook * _Nullable sharedNotebook, NSError * _Nullable error) {
        (error == nil) ? success(sharedNotebook) : failure(error);
    }];
}

- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                        success:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure
{
    [self emailNoteWithParameters:parameters completion:^(NSError * _Nonnull error) {
        (error == nil) ? success() : failure(error);
    }];
}

- (void)shareNoteWithGuid:(EDAMGuid)guid
                  success:(void(^)(NSString *noteKey))success
                  failure:(void(^)(NSError *error))failure
{
    [self shareNoteWithGuid:guid completion:^(NSString * _Nullable noteKey, NSError * _Nullable error) {
        (error == nil) ? success(noteKey) : failure(error);
    }];
}

- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                        success:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure
{
    [self stopSharingNoteWithGuid:guid completion:^(NSError * _Nonnull error) {
        (error == nil) ? success() : failure(error);
    }];
}

- (void)authenticateToSharedNoteWithGuid:(NSString *)guid
                                 noteKey:(NSString *)noteKey
                     authenticationToken:(nullable NSString*)authenticationToken
                                 success:(void(^)(EDAMAuthenticationResult *result))success
                                 failure:(void(^)(NSError *error))failure
{
    [self authenticateToSharedNoteWithGuid:guid noteKey:noteKey authenticationToken:authenticationToken completion:^(EDAMAuthenticationResult * _Nullable result, NSError * _Nullable error) {
        (error == nil) ? success(result) : failure(error);
    }];
}

- (void)updateSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
{
    [self updateSharedNotebook:sharedNotebook completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

- (void) setSharedNotebookRecipientSettingsWithSharedNotebookId: (int64_t) sharedNotebookId
                                              recipientSettings: (EDAMSharedNotebookRecipientSettings *) recipientSettings
                                                        success:(void(^)(int32_t usn))success
                                                        failure:(void(^)(NSError *error))failure
{
    [self setRecipientSettings:recipientSettings forSharedNotebookWithID:sharedNotebookId completion:^(int32_t usn, NSError * _Nullable error) {
        (error == nil) ? success(usn) : failure(error);
    }];
}

@end
