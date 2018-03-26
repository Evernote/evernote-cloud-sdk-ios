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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "EDAM.h"
#import "ENStoreClient.h"

@class EDAMSyncState, EDAMSyncChunk, EDAMSyncChunkFilter;
@class EDAMNotebook, EDAMLinkedNotebook, EDAMSharedNotebook, EDAMSharedNotebookRecipientSettings;
@class EDAMNote, EDAMTag, EDAMResource, EDAMResourceAttributes;
@class EDAMSavedSearch, EDAMRelatedQuery, EDAMRelatedResultSpec;
@class EDAMNoteFilter, EDAMNoteList, EDAMNotesMetadataResultSpec, EDAMNoteCollectionCounts;
@class EDAMLazyMap;
@class EDAMAuthenticationResult;
@class EDAMNoteEmailParameters;

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ENResourceFetchOption) {
    /**
            Fetches the data for the resource, populating its data property
        */
    ENResourceFetchOptionIncludeData = 1 << 0,
    /**
            Fetches any recognition data for the resource, populating its recognition property
        */
    ENResourceFetchOptionIncludeRecognitionData = 1 << 1,
    /**
            Fetches any alternate form for the resource's data, populating its alternateData property
        */
    ENResourceFetchOptionIncludeAlternateData = 1 << 2,
    /**
            Fetches the attributes for the resource, populating its attributes property
        */
    ENResourceFetchOptionIncludeAttributes = 1 << 3,
};

typedef void (^ENNoteStoreClientProgressHandler)(CGFloat progress);

// ! DO NOT INSTANTIATE THIS OBJECT DIRECTLY. GET ONE FROM AN AUTHENTICATED ENSESSION !

@interface ENNoteStoreClient : ENStoreClient
@property (nonatomic, strong, nullable) ENNoteStoreClientProgressHandler uploadProgressHandler DEPRECATED_MSG_ATTRIBUTE("Progress handlers are no longer supported") NS_SWIFT_UNAVAILABLE("Deprecated");
@property (nonatomic, strong, nullable) ENNoteStoreClientProgressHandler downloadProgressHandler DEPRECATED_MSG_ATTRIBUTE("Progress handlers are no longer supported") NS_SWIFT_UNAVAILABLE("Deprecated");

///---------------------------------------------------------------------------------------
/// @name NoteStore sync methods
///---------------------------------------------------------------------------------------

/** Asks the NoteStore to provide information about the status of the user account corresponding to the provided authentication token.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSyncStateWithCompletion:(void(^)(EDAMSyncState *_Nullable syncState, NSError *_Nullable error))completion;

/** Asks the NoteStore to provide the state of the account in order of last modification.
 
 This request retrieves one block of the server's state so that a client can make several small requests against a large account rather than getting the entire state in one big message.
 
 @param  afterUSN The client can pass this value to ask only for objects that have been updated after a certain point. This allows the client to receive updates after its last checkpoint rather than doing a full synchronization on every pass. The default value of "0" indicates that the client wants to get objects from the start of the account.
 
 @param  maxEntries The maximum number of modified objects that should be returned in the result SyncChunk. This can be used to limit the size of each individual message to be friendly for network transfer. Applications should not request more than 256 objects at a time, and must handle the case where the service returns less than the requested number of objects in a given request even though more objects are available on the service.
 
 @param  fullSyncOnly If true, then the client only wants initial data for a full sync. In this case, the service will not return any expunged objects, and will not return any Resources, since these are also provided in their corresponding Notes.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSyncChunkAfterUSN:(int32_t)afterUSN
                    maxEntries:(int32_t)maxEntries
                  fullSyncOnly:(BOOL)fullSyncOnly
                    completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion;

/** Asks the NoteStore to provide the state of the account in order of last modification.
 
 This request retrieves one block of the server's state so that a client can make several small requests against a large account rather than getting the entire state in one big message. This call gives more fine-grained control of the data that will be received by a client by omitting data elements that a client doesn't need. This may reduce network traffic and sync times.
 
 @param  afterUSN The client can pass this value to ask only for objects that have been updated after a certain point. This allows the client to receive updates after its last checkpoint rather than doing a full synchronization on every pass. The default value of "0" indicates that the client wants to get objects from the start of the account.
 
 @param  maxEntries The maximum number of modified objects that should be returned in the result SyncChunk. This can be used to limit the size of each individual message to be friendly for network transfer.
 
 @param  filter The caller must set some of the flags in this structure to specify which data types should be returned during the synchronization. See the SyncChunkFilter structure for information on each flag.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                            maxEntries:(int32_t)maxEntries
                                filter:(EDAMSyncChunkFilter *)filter
                            completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion;

/** Asks the NoteStore to provide information about the status of a linked notebook that has been shared with the caller, or that is public to the world.
 
 This will return a result that is similar to getSyncState, but may omit SyncState.uploaded if the caller doesn't have permission to write to the linked notebook.
 This function must be called on the shard that owns the referenced notebook. (I.e. the shardId in /shard/shardId/edam/note must be the same as LinkedNotebook.shardId.)
 
 @param  linkedNotebook This structure should contain identifying information and permissions to access the notebook in question.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSyncStateForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                             completion:(void(^)(EDAMSyncState *_Nullable syncState, NSError *_Nullable error))completion;

/** Asks the NoteStore to provide information about the contents of a linked notebook that has been shared with the caller, or that is public to the world.
 
 This will return a result that is similar to getSyncChunk, but will only contain entries that are visible to the caller. I.e. only that particular Notebook will be visible, along with its Notes, and Tags on those Notes.
 This function must be called on the shard that owns the referenced notebook. (I.e. the shardId in /shard/shardId/edam/note must be the same as LinkedNotebook.shardId.)
 
 @param  linkedNotebook This structure should contain identifying information and permissions to access the notebook in question. This must contain the valid fields for either a shared notebook (e.g. shareKey) or a public notebook (e.g. username, uri)
 
 @param  afterUSN The client can pass this value to ask only for objects that have been updated after a certain point. This allows the client to receive updates after its last checkpoint rather than doing a full synchronization on every pass. The default value of "0" indicates that the client wants to get objects from the start of the account.
 
 @param  maxEntries The maximum number of modified objects that should be returned in the result SyncChunk. This can be used to limit the size of each individual message to be friendly for network transfer. Applications should not request more than 256 objects at a time, and must handle the case where the service returns less than the requested number of objects in a given request even though more objects are available on the service.
 
 @param  fullSyncOnly If true, then the client only wants initial data for a full sync. In this case, the service will not return any expunged objects, and will not return any Resources, since these are also provided in their corresponding Notes.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSyncChunkForLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                               afterUSN:(int32_t)afterUSN
                             maxEntries:(int32_t)maxEntries
                           fullSyncOnly:(BOOL)fullSyncOnly
                             completion:(void(^)(EDAMSyncChunk *_Nullable syncChunk, NSError *_Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name NoteStore notebook methods
///---------------------------------------------------------------------------------------

/** Returns a list of all of the notebooks in the account.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listNotebooksWithCompletion:(void(^)(NSArray<EDAMNotebook *> *_Nullable notebooks, NSError *_Nullable error))completion;

/** Returns the current state of the notebook with the provided GUID. The notebook may be active or deleted (but not expunged).
 
 @param  guid The GUID of the notebook to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNotebookWithGuid:(EDAMGuid)guid
                   completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion;


/** Returns the notebook that should be used to store new notes in the user's account when no other notebooks are specified.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchDefaultNotebookWithCompletion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion;


/** Asks the service to make a notebook with the provided name.
 
 @param  notebook The desired fields for the notebook must be provided on this object. The name of the notebook must be set, and either the 'active' or 'defaultNotebook' fields may be set by the client at creation. If a notebook exists in the account with the same name (via case-insensitive compare), this will throw an EDAMUserException.
 
 @param completion Success completion block with the newly created Notebook. The server-side GUID will be saved in this object's 'guid' field.
 */
- (void)createNotebook:(EDAMNotebook *)notebook
            completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Submits notebook changes to the service. The provided data must include the notebook's guid field for identification.
 
 @param  notebook The notebook object containing the requested changes.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateNotebook:(EDAMNotebook *)notebook
            completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Permanently removes the notebook from the user's account. After this action, the notebook is no longer available for undeletion, etc. If the notebook contains any Notes, they will be moved to the current default notebook and moved into the trash (i.e. Note.active=false).
 
 @param  guid The GUID of the notebook to delete.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                     completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name NoteStore tag methods
///---------------------------------------------------------------------------------------

/** Returns a list of the tags in the account. Evernote does not support the undeletion of tags, so this will only include active tags.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listTagsWithCompletion:(void(^)(NSArray<EDAMTag *> *_Nullable tags, NSError *_Nullable error))completion;

/** Returns a list of the tags that are applied to at least one note within the provided notebook. If the notebook is public, the authenticationToken may be ignored.
 
 @param  guid the GUID of the notebook to use to find tags
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listTagsInNotebookWithGuid:(EDAMGuid)guid
                        completion:(void(^)(NSArray<EDAMTag *> * _Nullable tags, NSError *_Nullable error))completion;

/** Returns the current state of the Tag with the provided GUID.
 
 @param  guid The GUID of the tag to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchTagWithGuid:(EDAMGuid)guid
              completion:(void(^)(EDAMTag *_Nullable tag, NSError *_Nullable error))completion;

/** Asks the service to make a tag with a set of information.
 
 @param  tag The desired list of fields for the tag are specified in this object. The caller must specify the tag name, and may provide the parentGUID.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)createTag:(EDAMTag *)tag
       completion:(void(^)(EDAMTag *_Nullable tag, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Submits tag changes to the service. The provided data must include the tag's guid field for identification. The service will apply updates to the following tag fields: name, parentGuid
 
 @param  tag The tag object containing the requested changes.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateTag:(EDAMTag *)tag
       completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Removes the provided tag from every note that is currently tagged with this tag. If this operation is successful, the tag will still be in the account, but it will not be tagged on any notes.
 
 This function is not indended for use by full synchronizing clients, since it does not provide enough result information to the client to reconcile the local state without performing a follow-up sync from the service. This is intended for "thin clients" that need to efficiently support this as a UI operation.
 
 @param  guid The GUID of the tag to remove from all notes.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)untagAllWithGuid:(EDAMGuid)guid
              completion:(void(^)(NSError *error))completion;

/** Permanently deletes the tag with the provided GUID, if present.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param  guid The GUID of the tag to delete.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeTagWithGuid:(EDAMGuid)guid
                completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;
///---------------------------------------------------------------------------------------
/// @name NoteStore SavedSearch methods
///---------------------------------------------------------------------------------------

/** Returns a list of the searches in the account. Evernote does not support the undeletion of searches, so this will only include active searches.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listSearchesWithCompletion:(void(^)(NSArray<EDAMSavedSearch *> *_Nullable searches, NSError *_Nullable error))completion;

/** Returns the current state of the search with the provided GUID.
 
 @param  guid The GUID of the search to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSearchWithGuid:(EDAMGuid)guid
                 completion:(void(^)(EDAMSavedSearch *_Nullable search, NSError *_Nullable error))completion;

/** Asks the service to make a saved search with a set of information.
 
 @param  search The desired list of fields for the search are specified in this object. The caller must specify the name, query, and format of the search.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)createSearch:(EDAMSavedSearch *)search
          completion:(void(^)(EDAMSavedSearch *_Nullable search, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Submits search changes to the service. The provided data must include the search's guid field for identification. The service will apply updates to the following search fields: name, query, and format.
 
 @param  search The search object containing the requested changes.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateSearch:(EDAMSavedSearch *)search
          completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Permanently deletes the saved search with the provided GUID, if present.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param  guid The GUID of the search to delete.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeSearchWithGuid:(EDAMGuid)guid
                   completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;
///---------------------------------------------------------------------------------------
/// @name NoteStore notes methods
///---------------------------------------------------------------------------------------

/** Identify related entities on the service, such as notes, notebooks, and tags related to notes or content.
 
 @param  query The information about which we are finding related entities.
 @param  resultSpec Allows the client to indicate the type and quantity of information to be returned, allowing a saving of time and bandwidth.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)findRelatedWithQuery:(EDAMRelatedQuery *)query
                  resultSpec:(EDAMRelatedResultSpec *)resultSpec
                  completion:(void(^)(EDAMRelatedResult *_Nullable result, NSError *_Nullable error))completion;

/** Used to find a set of the notes from a user's account based on various criteria specified via a NoteFilter object.
 
 The Notes (and any embedded Resources) will have empty Data bodies for contents, resource data, and resource recognition fields. These values must be retrieved individually.
 
 @param  filter The list of criteria that will constrain the notes to be returned.
 
 @param  offset The numeric index of the first note to show within the sorted results. The numbering scheme starts with "0". This can be used for pagination.
 
 @param  maxNotes The most notes to return in this query. The service will return a set of notes that is no larger than this number, but may return fewer notes if needed. The NoteList.totalNotes field in the return value will indicate whether there are more values available after the returned set.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)findNotesWithFilter:(EDAMNoteFilter *)filter
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                 completion:(void(^)(EDAMNoteList *_Nullable list, NSError *_Nullable error))completion;

/** Finds the position of a note within a sorted subset of all of the user's notes.
 
 This may be useful for thin clients that are displaying a paginated listing of a large account, which need to know where a particular note sits in the list without retrieving all notes first.
 
 @param  filter The list of criteria that will constrain the notes to be returned.
 
 @param  guid The GUID of the note to be retrieved.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter
                            guid:(EDAMGuid)guid
                      completion:(void(^)(int32_t offset , NSError *_Nullable error))completion;

/** Used to find the high-level information about a set of the notes from a user's account based on various criteria specified via a NoteFilter object.
 
 This should be used instead of 'findNotes' whenever the client doesn't really need all of the deep structure of every Note and Resource, but just wants a high-level list of information. This will save time and bandwidth.
 
 @param  filter The list of criteria that will constrain the notes to be returned.
 
 @param  offset The numeric index of the first note to show within the sorted results. The numbering scheme starts with "0". This can be used for pagination.
 
 @param  maxNotes The mximum notes to return in this query. The service will return a set of notes that is no larger than this number, but may return fewer notes if needed. The NoteList.totalNotes field in the return value will indicate whether there are more values available after the returned set.
 
 @param  resultSpec This specifies which information should be returned for each matching Note. The fields on this structure can be used to eliminate data that the client doesn't need, which will reduce the time and bandwidth to receive and process the reply.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset
                           maxNotes:(int32_t)maxNotes
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                         completion:(void(^)(EDAMNotesMetadataList *_Nullable metadata, NSError *_Nullable error))completion;

/** This function is used to determine how many notes are found for each notebook and tag in the user's account, given a current set of filter parameters that determine the current selection.
 
 This function will return a structure that gives the note count for each notebook and tag that has at least one note under the requested filter. Any notebook or tag that has zero notes in the filtered set will not be listed in the reply to this function (so they can be assumed to be 0).
 
 @param  filter The note selection filter that is currently being applied. The note counts are to be calculated with this filter applied to the total set of notes in the user's account.
 
 @param  includingTrash If true, then the NoteCollectionCounts.trashCount will be calculated and supplied in the reply. Otherwise, the trash value will be omitted.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter
                  includingTrash:(BOOL)includingTrash
                      completion:(void(^)(EDAMNoteCollectionCounts *_Nullable counts, NSError *_Nullable error))completion;

/** Returns the current state of the note in the service with the provided GUID. The ENML contents of the note will only be provided if the 'withContent' parameter is true.
 
 The service will include the meta-data for each resource in the note, but the binary contents of the resources and their recognition data will be omitted. If the Note is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string). The applicationData fields are returned as keysOnly.
 
 @param  guid The GUID of the note to be retrieved.
 
 @param  includingContent If true, the note will include the ENML contents of its 'content' field.
 
 @param  resourceOptions The options for fetching resource data
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNoteWithGuid:(EDAMGuid)guid
         includingContent:(BOOL)includingContent
          resourceOptions:(ENResourceFetchOption)resourceOptions
               completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion;

/** Get all of the application data for the note identified by GUID, with values returned within the LazyMap fullMap field.
 
 If there are no applicationData entries, then a LazyMap with an empty fullMap will be returned. If your application only needs to fetch its own applicationData entry, use getNoteApplicationDataEntry instead.
 
 @param  guid The GUID of the note who's application data is to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNoteApplicationDataWithGuid:(EDAMGuid)guid
                              completion:(void(^)(EDAMLazyMap *_Nullable map, NSError *_Nullable error))completion;

/** Get the value of a single entry in the applicationData map for the note identified by GUID.
 
 @param  guid The GUID of the note
 @param key The key in the dictionary
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *)key
                                   completion:(void(^)(NSString *_Nullable entry, NSError *_Nullable error))completion;

/** Update, or create, an entry in the applicationData map for the note identified by guid.
 
 @param  guid The GUID of the note
 @param key The key in the dictionary
 @param value The value in the dictionary
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                      value:(NSString *)value
                                 completion:(void(^)(int32_t usn, NSError *_Nullable error))completion;

/** Remove an entry identified by 'key' from the applicationData map for the note identified by 'guid'. Silently ignores an unset of a non-existing key.
 
 @param  guid The GUID of the note
 @param key key from applicationData map
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *) key
                                   completion:(void(^)(int32_t usn, NSError *_Nullable error))completion;

/** Returns XHTML contents of the note with the provided GUID. If the Note is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the note to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNoteContentWithGuid:(EDAMGuid)guid
                      completion:(void(^)(NSString *_Nullable content, NSError *_Nullable error))completion;

/** Returns a block of the extracted plain text contents of the note with the provided GUID.
 
 This text can be indexed for search purposes by a light client that doesn't have capabilities to extract all of the searchable text content from the note and its resources. If the Note is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the note to be retrieved.
 
 @param  noteOnly If true, this will only return the text extracted from the ENML contents of the note itself. If false, this will also include the extracted text from any text-bearing resources (PDF, recognized images)
 
 @param  tokenizeForIndexing If true, this will break the text into cleanly separated and sanitized tokens. If false, this will return the more raw text extraction, with its original punctuation, capitalization, spacing, etc.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSearchTextForNoteWithGuid:(EDAMGuid)guid
                              noteOnly:(BOOL)noteOnly
                   tokenizeForIndexing:(BOOL)tokenizeForIndexing
                            completion:(void(^)(NSString *_Nullable text, NSError *_Nullable error))completion;

/** Returns a block of the extracted plain text contents of the resource with the provided GUID.
 
 This text can be indexed for search purposes by a light client that doesn't have capability to extract all of the searchable text content from a resource. If the Resource is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the resource to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSearchTextForResourceWithGuid:(EDAMGuid)guid
                                completion:(void(^)(NSString *_Nullable text, NSError *_Nullable error))completion;

/** Returns a list of the names of the tags for the note with the provided guid.
 
 This can be used with authentication to get the tags for a user's own note, or can be used without valid authentication to retrieve the names of the tags for a note in a public notebook.
 
 @param  guid The GUID of the note.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchTagNamesForNoteWithGuid:(EDAMGuid)guid
                          completion:(void(^)(NSArray<NSString *> *_Nullable names, NSError *_Nullable error))completion;

/** Asks the service to make a note with the provided set of information.
 
 @param  note A Note object containing the desired fields to be populated on the service.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 @exception EDAMUserException Thrown if the note is not valid.
 @exception EDAMNotFoundException If the note is not found by GUID
 */
- (void)createNote:(EDAMNote *)note
        completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Submit a set of changes to a note to the service.
 
 The provided data must include the note's guid field for identification. The note's title must also be set.
 
 @param  note A Note object containing the desired fields to be populated on the service. With the exception of the note's title and guid, fields that are not being changed do not need to be set. If the content is not being modified, note.content should be left unset. If the list of resources is not being modified, note.resources should be left unset.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateNote:(EDAMNote *)note
        completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion;

/** Moves the note into the trash. The note may still be undeleted, unless it is expunged.
 
 This is equivalent to calling updateNote() after setting Note.active = false
 
 @param  guid The GUID of the note to delete.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)deleteNoteWithGuid:(EDAMGuid)guid
                completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Permanently removes a Note, and all of its Resources, from the service.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param  guid The GUID of the note to delete.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeNoteWithGuid:(EDAMGuid)guid
                 completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Permanently removes a list of Notes, and all of their Resources, from the service.
 
 This should be invoked with a small number of Note GUIDs (e.g. 100 or less) on each call. To expunge a larger number of notes, call this method multiple times. This should also be used to reduce the number of Notes in a notebook before calling expungeNotebook() or in the trash before calling expungeInactiveNotes(), since these calls may be prohibitively slow if there are more than a few hundred notes. If an exception is thrown for any of the GUIDs, then none of the notes will be deleted. I.e. this call can be treated as an atomic transaction.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param  guids The list of GUIDs for the Notes to remove.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeNotesWithGuids:(NSArray<EDAMGuid> *)guids
                   completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Permanently removes all of the Notes that are currently marked as inactive.
 
 This is equivalent to "emptying the trash", and these Notes will be gone permanently. This operation may be relatively slow if the account contains a large number of inactive Notes.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeInactiveNoteWithCompletion:(void(^)(int32_t , NSError *_Nullable error))completion;

/** Performs a deep copy of the Note with the provided GUID 'noteGuid' into the Notebook with the provided GUID 'toNotebookGuid'.
 
 The caller must be the owner of both the Note and the Notebook. This creates a new Note in the destination Notebook with new content and Resources that match all of the content and Resources from the original Note, but with new GUID identifiers. The original Note is not modified by this operation. The copied note is considered as an "upload" for the purpose of upload transfer limit calculation, so its size is added to the upload count for the owner.
 
 @param  guid The GUID of the Note to copy.
 
 @param  notebookGuid The GUID of the Notebook that should receive the new Note.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)copyNoteWithGuid:(EDAMGuid)guid
      toNotebookWithGuid:(EDAMGuid)notebookGuid
              completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion;

/** Returns a list of the prior versions of a particular note that are saved within the service.
 
 These prior versions are stored to provide a recovery from unintentional removal of content from a note. The identifiers that are returned by this call can be used with getNoteVersion to retrieve the previous note. The identifiers will be listed from the most recent versions to the oldest.
 
 @param  guid The GUID of the Note.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                      completion:(void(^)(NSArray<EDAMNoteVersionId *> *_Nullable versions, NSError *_Nullable error))completion;

/** This can be used to retrieve a previous version of a Note after it has been updated within the service.
 
 The caller must identify the note (via its guid) and the version (via the updateSequenceNumber of that version). to find a listing of the stored version USNs for a note, call listNoteVersions. This call is only available for notes in Premium accounts. (I.e. access to past versions of Notes is a Premium-only feature.)
 
 @param  guid The GUID of the note to be retrieved.
 
 @param  updateSequenceNum The USN of the version of the note that is being retrieved
 
 @param  resourceOptions The options for fetching resource data
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchNoteVersionWithGuid:(EDAMGuid)guid
               updateSequenceNum:(int32_t)updateSequenceNum
                 resourceOptions:(ENResourceFetchOption)resourceOptions
                      completion:(void(^)(EDAMNote *_Nullable note, NSError *_Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name NoteStore resource methods
///---------------------------------------------------------------------------------------

/** Returns the current state of the resource in the service with the provided GUID.
 
 If the Resource is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string). Only the keys for the applicationData will be returned.
 
 @param  guid The GUID of the resource to be retrieved.

 @param  options The options for fetching resource data
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchResourceWithGuid:(EDAMGuid)guid
                      options:(ENResourceFetchOption)options
                   completion:(void(^)(EDAMResource *_Nullable resource, NSError *_Nullable error))completion;

/** Get all of the application data for the Resource identified by GUID, with values returned within the LazyMap fullMap field. If there are no applicationData entries, then a LazyMap with an empty fullMap will be returned. If your application only needs to fetch its own applicationData entry, use getResourceApplicationDataEntry instead.
 
 @param  guid The GUID of the Resource.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchResourceApplicationDataWithGuid:(EDAMGuid)guid
                                  completion:(void(^)(EDAMLazyMap *_Nullable map, NSError *_Nullable error))completion;

/** Get the value of a single entry in the applicationData map for the Resource identified by GUID.
 
 @param  guid The GUID of the Resource.
 @param key key in the dictionary
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                       completion:(void(^)(NSString *_Nullable entry, NSError *_Nullable error))completion NS_SWIFT_NAME(fetchResourceApplicationDataEntryWith(guid:key:completion:));;

/** Update, or create, an entry in the applicationData map for the Resource identified by guid.
 
 @param  guid The GUID of the Resource.
 @param key key in the dictionary
 @param value value in the dictionary
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                          value:(NSString *)value
                                     completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Remove an entry identified by 'key' from the applicationData map for the Resource identified by 'guid'.
 
 @param  guid The GUID of the Resource.
 @param key key in the dictionary
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                       completion:(void(^)(int32_t usn , NSError *_Nullable error))completion NS_SWIFT_NAME(unsetResourceApplicationDataEntryWith(guid:key:completion:));

/** Submit a set of changes to a resource to the service.
 
 This can be used to update the meta-data about the resource, but cannot be used to change the binary contents of the resource (including the length and hash). These cannot be changed directly without creating a new resource and removing the old one via updateNote.
 
 @param  resource A Resource object containing the desired fields to be populated on the service. The service will attempt to update the resource with the following fields from the client: guid(must be provided to identify the resource),mime,width,height,duration,attributes(optional. if present, the set of attributes will be replaced).
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateResource:(EDAMResource *)resource
            completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Returns binary data of the resource with the provided GUID.
 
 For example, if this were an image resource, this would contain the raw bits of the image. If the Resource is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the resource to be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchResourceDataWithGuid:(EDAMGuid)guid
                       completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion;

/** Returns the current state of a resource, referenced by containing note GUID and resource content hash.
 
 @param  guid The GUID of the note that holds the resource to be retrieved.
 
 @param  contentHash The MD5 checksum of the resource within that note. Note that this is the binary checksum, for example from Resource.data.bodyHash, and not the hex-encoded checksum that is used within an en-media tag in a note body.
 
 @param  options The options for fetching resource data
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchResourceByHashWithGuid:(EDAMGuid)guid
                        contentHash:(NSData *)contentHash
                            options:(ENResourceFetchOption)options
                         completion:(void(^)(EDAMResource *_Nullable resource, NSError *_Nullable error))completion NS_SWIFT_NAME(fetchResourceByHashWith(guid:contentHash:options:completion:));


/** Returns the binary contents of the recognition index for the resource with the provided GUID.
 
 If the caller asks about a resource that has no recognition data, this will throw EDAMNotFoundException. If the Resource is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the resource whose recognition data should be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchRecognitionDataForResourceWithGuid:(EDAMGuid)guid
                                        completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion;

/** If the Resource with the provided GUID has an alternate data representation (indicated via the Resource.alternateData field), then this request can be used to retrieve the binary contents of that alternate data file. If the caller asks about a resource that has no alternate data form, this will throw EDAMNotFoundException.
 
 @param  guid The GUID of the resource whose recognition data should be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchAlternateDataForResourceWithGuid:(EDAMGuid)guid
                                   completion:(void(^)(NSData *_Nullable data, NSError *_Nullable error))completion;

/** Returns the set of attributes for the Resource with the provided GUID. If the Resource is found in a public notebook, the authenticationToken will be ignored (so it could be an empty string).
 
 @param  guid The GUID of the resource whose attributes should be retrieved.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchAttributesForResourceWithGuid:(EDAMGuid)guid
                                completion:(void(^)(EDAMResourceAttributes *_Nullable attributes, NSError *_Nullable error))completion;

///---------------------------------------------------------------------------------------
/// @name NoteStore shared notebook methods
///---------------------------------------------------------------------------------------

/** Looks for a user account with the provided userId on this NoteStore shard and determines whether that account contains a public notebook with the given URI.
 
 If the account is not found, or no public notebook exists with this URI, this will throw an EDAMNotFoundException, otherwise this will return the information for that Notebook. If a notebook is visible on the web with a full URL like http://www.evernote.com/pub/sethdemo/api Then 'sethdemo' is the username that can be used to look up the userId, and 'api' is the publicUri.
 
 @param  userId The numeric identifier for the user who owns the public notebook. To find this value based on a username string, you can invoke UserStore.getPublicUserInfo
 @param  publicURI The uri string for the public notebook, from Notebook.publishing.uri.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchPublicNotebookWithUserID:(EDAMUserID)userId
                            publicURI:(NSString *)publicURI
                           completion:(void(^)(EDAMNotebook *_Nullable notebook, NSError *_Nullable error))completion NS_SWIFT_NAME(fetchPublicNotebookWith(userID:publicURI:completion:));

/** Used to construct a shared notebook object. The constructed notebook will contain a "share key" which serve as a unique identifer and access token for a user to access the notebook of the shared notebook owner.
 
 @param  sharedNotebook An shared notebook object populated with the email address of the share recipient, the notebook guid and the access permissions. All other attributes of the shared object are ignored.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                  completion:(void(^)(EDAMSharedNotebook *_Nullable sharedNotebook, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Send a reminder message to some or all of the email addresses that a notebook has been shared with.
 
 The message includes the current link to view the notebook.
 
 @param  guid The guid of the shared notebook
 @param  messageText User provided text to include in the email
 @param  recipients The email addresses of the recipients. If this list is empty then all of the users that the notebook has been shared with are emailed. If an email address doesn't correspond to share invite members then that address is ignored.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)sendMessageToMembersOfSharedNotebookWithGuid:(EDAMGuid)guid
                                         messageText:(NSString *)messageText
                                          recipients:(NSArray<NSString *> *)recipients
                                          completion:(void(^)(int32_t numMessagesSent , NSError *_Nullable error))completion;

/** Lists the collection of shared notebooks for all notebooks in the users account.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listSharedNotebooksWithCompletion:(void(^)(NSArray<EDAMSharedNotebook *> *_Nullable sharedNotebooks, NSError *_Nullable error))completion;

/** Expunges the SharedNotebooks in the user's account using the SharedNotebook.id as the identifier.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param sharedNotebookIds a list of ShardNotebook.id longs identifying the objects to delete permanently.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeSharedNotebooksWithIds:(NSArray<NSNumber *> *)sharedNotebookIds
                           completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Asks the service to make a linked notebook with the provided name, username of the owner and identifiers provided.
 
 A linked notebook can be either a link to a public notebook or to a private shared notebook.
 
 @param  linkedNotebook The desired fields for the linked notebook must be provided on this object. The name of the linked notebook must be set. Either a username uri or a shard id and share key must be provided otherwise a EDAMUserException is thrown.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                  completion:(void(^)(EDAMLinkedNotebook *_Nullable linkedNotebook, NSError *_Nullable error))completion NS_SWIFT_NAME(create(_:completion:));

/** Asks the service to update a linked notebook.
 
 @param  linkedNotebook Updates the name of a linked notebook.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Returns a list of linked notebooks
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)listLinkedNotebooksWithCompletion:(void(^)(NSArray<EDAMLinkedNotebook *> *_Nullable linkedNotebooks, NSError *_Nullable error))completion;

/** Permanently expunges the linked notebook from the account.
 
 NOTE: This function is not available to third party applications. Calls will result in an EDAMUserException with the error code PERMISSION_DENIED.
 
 @param  guid The LinkedNotebook.guid field of the LinkedNotebook to permanently remove from the account.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                           completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Asks the service to produce an authentication token that can be used to access the contents of a shared notebook from someone else's account.
 
 This authenticationToken can be used with the various other NoteStore calls to find and retrieve notes, and if the permissions in the shared notebook are sufficient, to make changes to the contents of the notebook.
 
 @param  shareKeyOrGlobalId The 'shareKey' (or 'globalId') identifier from the SharedNotebook that was granted to some recipient. This string internally encodes the notebook identifier and a security signature.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)authenticateToSharedNotebook:(NSString *)shareKeyOrGlobalId
                             completion:(void(^)(EDAMAuthenticationResult *_Nullable result, NSError *_Nullable error))completion;

/** This function is used to retrieve extended information about a shared notebook by a guest who has already authenticated to access that notebook.
 
 This requires an 'authenticationToken' parameter which should be the resut of a call to authenticateToSharedNotebook(...). I.e. this is the token that gives access to the particular shared notebook in someone else's account -- it's not the authenticationToken for the owner of the notebook itself.
 
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)fetchSharedNotebookByAuthWithCompletion:(void(^)(EDAMSharedNotebook *_Nullable sharedNotebook, NSError *_Nullable error))completion;

/** Attempts to send a single note to one or more email recipients.
 
 @param  parameters The note must be specified either by GUID (in which case it will be sent using the existing data in the service), or else the full Note must be passed to this call. This also specifies the additional email fields that will be used in the email.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                     completion:(void(^)(NSError *error))completion;

/** If this note is not already shared (via its own direct URL), then this will start sharing that note.
 
 This will return the secret "Note Key" for this note that can currently be used in conjunction with the Note's GUID to gain direct read-only access to the Note. If the note is already shared, then this won't make any changes to the note, and the existing "Note Key" will be returned. The only way to change the Note Key for an existing note is to stopSharingNote first, and then call this function.
 
 @param  guid The GUID of the note to be shared.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)shareNoteWithGuid:(EDAMGuid)guid
               completion:(void(^)(NSString *_Nullable noteKey, NSError *_Nullable error))completion;

/** If this note is not already shared then this will stop sharing that note and invalidate its "Note Key", so any existing URLs to access that Note will stop working. If the Note is not shared, then this function will do nothing.
 
 @param  guid The GUID of the note to be un-shared.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                     completion:(void(^)(NSError *error))completion;

/** Asks the service to produce an authentication token that can be used to access the contents of a single Note which was individually shared from someone's account.
 
 This authenticationToken can be used with the various other NoteStore calls to find and retrieve the Note and its directly-referenced children.
 
 @param  guid The GUID identifying this Note on this shard.
 @param  noteKey The 'noteKey' identifier from the Note that was originally created via a call to shareNote() and then given to a recipient to access.
 @param authenticationToken Optional, only required for Yinxiang
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)authenticateToSharedNoteWithGuid:(NSString *)guid
                                 noteKey:(NSString *)noteKey
                     authenticationToken:(nullable NSString*)authenticationToken
                              completion:(void(^)(EDAMAuthenticationResult *_Nullable result, NSError *_Nullable error))completion;

/** Update a SharedNotebook object.
 
 @param  sharedNotebook The SharedNotebook object containing the requested changes. The "id" of the shared notebook must be set to allow the service to identify the SharedNotebook to be updated. In addition, you MUST set the email, permission, and allowPreview fields to the desired values. All other fields will be ignored if set.
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)updateSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/** Set shared notebook recipient settings.
 
 @param sharedNotebookId The shared notebooks id
 @param recipientSettings The settings of the recipient
 @param completion Completion block (if the error parameter is set, then the value of the first parameter is undefined)
 */
- (void)setRecipientSettings:(EDAMSharedNotebookRecipientSettings *) recipientSettings
     forSharedNotebookWithID:(int64_t)sharedNotebookId
                  completion:(void(^)(int32_t usn , NSError *_Nullable error))completion;

/**
 *  Cancel the first operation on the note store queue
 */
- (void) cancelFirstOperation;

@end




//Deprecated
@interface ENNoteStoreClient ()

- (void)getSyncStateWithSuccess:(void(^)(EDAMSyncState *syncState))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSyncStateWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getSyncChunkAfterUSN:(int32_t)afterUSN
                  maxEntries:(int32_t)maxEntries
                fullSyncOnly:(BOOL)fullSyncOnly
                     success:(void(^)(EDAMSyncChunk *syncChunk))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSyncChunkAfterUSN:maxEntries:fullSyncOnly:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                          maxEntries:(int32_t)maxEntries
                              filter:(EDAMSyncChunkFilter *)filter
                             success:(void(^)(EDAMSyncChunk *syncChunk))success
                             failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchFilteredSyncChunkAfterUSN:maxEntries:filter:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getLinkedNotebookSyncState:(EDAMLinkedNotebook *)linkedNotebook
                           success:(void(^)(EDAMSyncState *syncState))success
                           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSyncStateForLinkedNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getLinkedNotebookSyncChunk:(EDAMLinkedNotebook *)linkedNotebook
                          afterUSN:(int32_t)afterUSN
                        maxEntries:(int32_t)maxEntries
                      fullSyncOnly:(BOOL)fullSyncOnly
                           success:(void(^)(EDAMSyncChunk *syncChunk))success
                           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSyncChunkForLinkedNotebook:afterUSN:maxEntries:fullSyncOnly:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listNotebooksWithSuccess:(void(^)(NSArray<EDAMNotebook *> *notebooks))success
                         failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listNotebooksWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNotebookWithGuid:(EDAMGuid)guid
                    success:(void(^)(EDAMNotebook *notebook))success
                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNotebookWithGuid:success:failure: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getDefaultNotebookWithSuccess:(void(^)(EDAMNotebook *notebook))success
                              failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchDefaultNotebookWithSuccess:failure: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createNotebook:(EDAMNotebook *)notebook
               success:(void(^)(EDAMNotebook *notebook))success
               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateNotebook:(EDAMNotebook *)notebook
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                        success:(void(^)(int32_t usn))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeNotebookWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listTagsWithSuccess:(void(^)(NSArray<EDAMTag *> *tags))success
                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listTagsWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listTagsByNotebookWithGuid:(EDAMGuid)guid
                           success:(void(^)(NSArray<EDAMTag *> *tags))success
                           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listTagsInNotebookWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getTagWithGuid:(EDAMGuid)guid
               success:(void(^)(EDAMTag *tag))success
               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchTagWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createTag:(EDAMTag *)tag
          success:(void(^)(EDAMTag *tag))success
          failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createTag:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateTag:(EDAMTag *)tag
          success:(void(^)(int32_t usn))success
          failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateTag:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)untagAllWithGuid:(EDAMGuid)guid
                 success:(void(^)(void))success
                 failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -untagAllWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeTagWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeTagWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listSearchesWithSuccess:(void(^)(NSArray<EDAMSavedSearch *> *searches))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listSearchesWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getSearchWithGuid:(EDAMGuid)guid
                  success:(void(^)(EDAMSavedSearch *search))success
                  failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSearchWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createSearch:(EDAMSavedSearch *)search
             success:(void(^)(EDAMSavedSearch *search))success
             failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createSearch:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateSearch:(EDAMSavedSearch *)search
             success:(void(^)(int32_t usn))success
             failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateSearch:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeSearchWithGuid:(EDAMGuid)guid
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeSearchWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)findRelatedWithQuery:(EDAMRelatedQuery *)query
                  resultSpec:(EDAMRelatedResultSpec *)resultSpec
                     success:(void(^)(EDAMRelatedResult *result))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -findRelatedWithQuery:resultSpect:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)findNotesWithFilter:(EDAMNoteFilter *)filter
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                    success:(void(^)(EDAMNoteList *list))success
                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -findNotesWithFilter:offset:maxNotes:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter
                            guid:(EDAMGuid)guid
                         success:(void(^)(int32_t offset))success
                         failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -findNoteOffsetWithFilter:guid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset
                           maxNotes:(int32_t)maxNotes
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(EDAMNotesMetadataList *metadata))success
                            failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -findNotesMetadataWithFilter:offset:maxNotes:resultSpec:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");


- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter
                       withTrash:(BOOL)withTrash
                         success:(void(^)(EDAMNoteCollectionCounts *counts))success
                         failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -findNoteCountsWithFilter:includingTrash:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteWithGuid:(EDAMGuid)guid
            withContent:(BOOL)withContent
      withResourcesData:(BOOL)withResourcesData
withResourcesRecognition:(BOOL)withResourcesRecognition
withResourcesAlternateData:(BOOL)withResourcesAlternateData
                success:(void(^)(EDAMNote *note))success
                failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNoteWithGuid:includingContent:resourceOptions:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteApplicationDataWithGuid:(EDAMGuid)guid
                               success:(void(^)(EDAMLazyMap *map))success
                               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNoteApplicationDataWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                    success:(void(^)(NSString *entry))success
                                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNoteApplicationDataEntryWithGuid:key:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                        key:(NSString *)key
                                      value:(NSString *)value
                                    success:(void(^)(int32_t usn))success
                                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -setNoteApplicationDataEntryWithGuid:key:value:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid
                                          key:(NSString *) key
                                      success:(void(^)(int32_t usn))success
                                      failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -unsetNoteApplicationDataEntryWithGuid:key:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteContentWithGuid:(EDAMGuid)guid
                       success:(void(^)(NSString *content))success
                       failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNoteContentWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteSearchTextWithGuid:(EDAMGuid)guid
                         noteOnly:(BOOL)noteOnly
              tokenizeForIndexing:(BOOL)tokenizeForIndexing
                          success:(void(^)(NSString *text))success
                          failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSearchTextNoteWithGuid:noteOnly:tokenizeForIndexing:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceSearchTextWithGuid:(EDAMGuid)guid
                              success:(void(^)(NSString *text))success
                              failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchSearchTextForResourceWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteTagNamesWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSArray<NSString *> *names))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchTagNamesForNoteWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createNote:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateNote:(EDAMNote *)note
           success:(void(^)(EDAMNote *note))success
           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateNote:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)deleteNoteWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -deleteNoteWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeNoteWithGuid:(EDAMGuid)guid
                    success:(void(^)(int32_t usn))success
                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeNoteWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeNotesWithGuids:(NSArray<EDAMGuid> *)guids
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeNotesWithGuids:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeInactiveNoteWithSuccess:(void(^)(int32_t usn))success
                               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeInactiveNoteWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)copyNoteWithGuid:(EDAMGuid)guid
          toNoteBookGuid:(EDAMGuid)toNotebookGuid
                 success:(void(^)(EDAMNote *note))success
                 failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -copyNoteWithGuid:toNotebookWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                         success:(void(^)(NSArray<EDAMNoteVersionId *> *versions))success
                         failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listNoteVersionsWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getNoteVersionWithGuid:(EDAMGuid)guid
             updateSequenceNum:(int32_t)updateSequenceNum
             withResourcesData:(BOOL)withResourcesData
      withResourcesRecognition:(BOOL)withResourcesRecognition
    withResourcesAlternateData:(BOOL)withResourcesAlternateData
                       success:(void(^)(EDAMNote *note))success
                       failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchNoteVersionWithGuid:updateSequenceNum:resourceOptions:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceWithGuid:(EDAMGuid)guid
                   withData:(BOOL)withData
            withRecognition:(BOOL)withRecognition
             withAttributes:(BOOL)withAttributes
          withAlternateDate:(BOOL)withAlternateData
                    success:(void(^)(EDAMResource *resource))success
                    failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchResourceWithGuid:options:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceApplicationDataWithGuid:(EDAMGuid)guid
                                   success:(void(^)(EDAMLazyMap *map))success
                                   failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchResourceApplicationDataWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                        success:(void(^)(NSString *entry))success
                                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchResourceApplicationDataWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                            key:(NSString *)key
                                          value:(NSString *)value
                                        success:(void(^)(int32_t usn))success
                                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -setResourceApplicationDataEntryWithGuid:key:value:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid
                                              key:(NSString *)key
                                          success:(void(^)(int32_t usn))success
                                          failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -unsetResourceApplicationDataEntryWithGuid:key:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateResource:(EDAMResource *)resource
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateResource:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceDataWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSData *data))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchResourceDataWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceByHashWithGuid:(EDAMGuid)guid
                      contentHash:(NSData *)contentHash
                         withData:(BOOL)withData
                  withRecognition:(BOOL)withRecognition
                withAlternateData:(BOOL)withAlternateData
                          success:(void(^)(EDAMResource *resource))success
                          failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchResourcebyHashWithGuid:contentHash:options:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceRecognitionWithGuid:(EDAMGuid)guid
                               success:(void(^)(NSData *data))success
                               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchRecognitionDataForResourceWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceAlternateDataWithGuid:(EDAMGuid)guid
                                 success:(void(^)(NSData *data))success
                                 failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchAlternateDataForResourceWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getResourceAttributesWithGuid:(EDAMGuid)guid
                              success:(void(^)(EDAMResourceAttributes *attributes))success
                              failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchAttributesForResourceWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getPublicNotebookWithUserID:(EDAMUserID)userId
                          publicUri:(NSString *)publicUri
                            success:(void(^)(EDAMNotebook *notebook))success
                            failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -fetchPublicNotebookWithUserID:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createSharedNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)sendMessageToSharedNotebookMembersWithGuid:(EDAMGuid)guid
                                       messageText:(NSString *)messageText
                                        recipients:(NSArray<NSString *> *)recipients
                                           success:(void(^)(int32_t numMessagesSent))success
                                           failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -senderMessageToMembersOfSharedNotebookWithGuid:messageText:recipients:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listSharedNotebooksWithSuccess:(void(^)(NSArray<EDAMSharedNotebook *> *sharedNotebooks))success
                               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listSharedNotebooksWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeSharedNotebooksWithIds:(NSArray<NSNumber *> *)sharedNotebookIds
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeSharedNotebooksWithIds:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(EDAMLinkedNotebook *linkedNotebook))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -createLinkedNotebook:completion instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateLinkedNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)listLinkedNotebooksWithSuccess:(void(^)(NSArray<EDAMLinkedNotebook *> *linkedNotebooks))success
                               failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -listLinkedNotebooksWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -expungeLinkedNotebookWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)authenticateToSharedNotebook:(NSString *)shareKeyOrGlobalId
                             success:(void(^)(EDAMAuthenticationResult *result))success
                             failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -authenticateToSharedNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)getSharedNotebookByAuthWithSuccess:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                                   failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -getSharedNotebookByAuthWithCompletion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                        success:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -emailNoteWithParameters:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)shareNoteWithGuid:(EDAMGuid)guid
                  success:(void(^)(NSString *noteKey))success
                  failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -shareNoteWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                        success:(void(^)(void))success
                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -stopSharingNoteWithGuid:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)authenticateToSharedNoteWithGuid:(NSString *)guid
                                 noteKey:(NSString *)noteKey
                     authenticationToken:(nullable NSString*)authenticationToken
                                 success:(void(^)(EDAMAuthenticationResult *result))success
                                 failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -authenticateToSharedNotebookWithGuid:noteKey:authenticationToken:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void)updateSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -updateSharedNotebook:completion: instead") NS_SWIFT_UNAVAILABLE("Deprecated");

- (void) setSharedNotebookRecipientSettingsWithSharedNotebookId: (int64_t) sharedNotebookId
                                              recipientSettings: (EDAMSharedNotebookRecipientSettings *) recipientSettings
                                                        success:(void(^)(int32_t usn))success
                                                        failure:(void(^)(NSError *error))failure
DEPRECATED_MSG_ATTRIBUTE("Use -setRecipientSettings:forSharedNotebookWithID:success:failure: instead") NS_SWIFT_UNAVAILABLE("Deprecated");



@end

NS_ASSUME_NONNULL_END
