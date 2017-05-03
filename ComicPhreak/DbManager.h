//
//  DbManager.h
//  Comic Phreak DB
//
//  Created by Mudit Vats on 9/8/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

//
// To Null Check an object, do the following --
//
//   NSDictionary *record = [results objectAtIndex:0];
//
//   if ([record objectForKey:@"TotalPages"] == [NSNull null])
//   { ....
//

/*
 Scenarios -
 1. Sync, [UI pauses], DB is updated, UI displays comics
 2. User deletes, DB is updated, UI is updated
 3. User does something with comic, metadata updated in DB, UI is updated
 4. User deletes many comics, DB is updated, UI is updated. <maybe not?>
 */

/*
 
 This is the database access library.
 This is actually the comic book table access library.
 
 */

#import <Foundation/Foundation.h>
#import "SQLiteManager.h"

@interface DbManager : NSObject

+ (DbManager *) sharedInstance;

//**************************************
// Create Operations
//**************************************

// Open / Close
- (BOOL) openDatabase;
- (BOOL) closeDatabase;

// Database Maintenance
- (BOOL) createDatabase;
- (BOOL) recreateDatabase;

// Comic Library Table Functions
- (BOOL) createLibraryTable;
- (BOOL) deleteLibraryTable;
- (BOOL) clearLibraryTable;

//**************************************
// Read Operations (Queries)
// - Many at a time
//**************************************

- (int) getNumberOfRowsThatAreValid;

// Getters (read operations; many of these can happen concurrently)
- (NSString *) getGroupNameByFileName: (NSString *) fileName;
- (NSString *) getDateCreatedByFileName: (NSString *) fileName;
- (NSString *) getDateModifiedByFileName: (NSString *) fileName;
- (NSString *) getDateAccessedByFileName: (NSString *) fileName;
- (int)        getFileSizeByFileName: (NSString *) fileName;
- (int)        getTotalPagesByFileName: (NSString *) fileName;
- (int)        getCurrentPageByFileName: (NSString *) fileName;
- (NSString *) getGetThumbNaileFileNameByFileName: (NSString *) fileName;
- (int)        getIsUnreadByFileName: (NSString *) fileName;
- (int)        getIsDeletedByFileName: (NSString *) fileName;
- (int)        getIsValidByFileName: (NSString *) fileName;

// Queries (read operations; many of these can happen concurrently)
- (NSDictionary *) getRecordByFileName: (NSString *) fileName;
- (NSDictionary *) getRecordByIndex: (int) index;

- (NSArray *) getAllRecordsInvalid;
//- (NSArray *) getAllRecordsValid;


//**************************************
// Write Operations
// - Atomic; One write at a time
//**************************************

// Update queries
- (BOOL) setFileNameInvalid: (NSString *) fileName;


- (BOOL) deleteRecordWithFileName: (NSString *) fileName;
//- (BOOL) deleteRecordWithIndex: (int) index;

// Get all records with sorting
- (NSArray *) getAllRecordsUnsorted;
- (NSArray *) getAllRecordsByFileNameAndSortByAlphaAscending;
- (NSArray *) getAllRecordsByFileNameAndSortByAlphaAscendingCaseSensitive;
- (NSArray *) getAllRecordsByFileNameAndSortByAlphaDescending;
- (NSArray *) getAllRecordsByFileNameAndSortByAlphaDescendingCaseSensitive;
- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaAscending: (NSString *) groupName;
- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaAscendingCaseSensitive: (NSString *) groupName;
- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaDescending: (NSString *) groupName;
- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaDescendingCaseSensitive: (NSString *) groupName;

// Insertion functions
- (BOOL) insertRecordWithName: (NSString *) fileName
				 AndGroupName: (NSString *) groupName
				  AndFileSize: (NSInteger)  fileSize
			   AndDateCreated: (NSString *) dateCreated
			  AndDateModified: (NSString *) dateModified
			  AndDateAccessed: (NSString *) dateAccessed
				AndTotalPages: (NSInteger)  totalPages
			   AndCurrentPage: (NSInteger)  currentPage
		 AndThumbNailFileName: (NSString *) thumbNailFileName
				  AndIsUnread: (NSInteger)  isUnread
				 AndIsDeleted: (NSInteger)  isDeleted
				   AndIsValid: (NSInteger)  isValid;

- (BOOL) insertRecordWithName: (NSString *) fileName
                 AndGroupName: (NSString *) groupName
                  AndFileSize: (NSInteger)  fileSize
                   AndIsValid: (NSInteger)  isValid;


//**************************************
// Debug Operations
//**************************************

// Record dump / debug functions
+ (void) printRecordWithDictionary: (NSDictionary *) dictionary;
+ (void) dumpAllRecordsWithDictionaryList: (NSArray *) list;

@end
