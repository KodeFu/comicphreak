//
//  DbManager.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 9/8/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import "DbManager.h"
#import "SQLiteManager.h"
#import "PathHelper.h"
#import "RandomData.h"
#import "Debug.h"

@interface DbManager()
{
@private
    SQLiteManager *_sqlm;
}
@end

@implementation DbManager

//static DbManager *g_dbManager = Nil;

#define SQL_DATABASE					@".data/comicphreak.db"
#define SQL_TABLE_LIBRARY				@"library"
#define SQL_TABLE_LIBRARY_NUM_COLUMNS	12


+ (DbManager *) sharedInstance
{
    static DbManager *sharedInstance = Nil;
    static dispatch_once_t onceToken = 0;
    
	dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        
        // DEBUG
        DLOG(@"++++++++++++++ CLEARING LIBRARY TABLE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ CLEARING LIBRARY TABLE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ CLEARING LIBRARY TABLE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ CLEARING LIBRARY TABLE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ CLEARING LIBRARY TABLE DEBUG ONLY ++++++++++++++++++++++");
        [sharedInstance clearLibraryTable];
    });
	
    return sharedInstance;
}

/*
+ (DbManager *) sharedInstance
{
	@synchronized(self)
	{
        if (g_dbManager == Nil)
		{
			g_dbManager = [[self alloc] init];
			
			// DEBUG Data
			[g_dbManager clearTable];
//			[RandomData GenerateRandomDataWithQuantity:1000];
		}
    }
	
    return g_dbManager;
}
*/

- (id) init
{
    self = [super init];
	
    if (self)
	{
		if (sqlite3_shutdown() != SQLITE_OK)
		{
			DLOG(@"sqlite could not be shutdown");
			return Nil;
		}
		
		// Enable one SQL connection to be used across multiple threads
		// - The same database connection can be used across multiple threads in this app
		//     (SQLITE_CONFIG_SERIALIZED). Read/writes are serialized across threads.
		// - Multiple processes can read the database at the same time. Only one process
		//     can write to it. This process locks the entire database. Not an issue for an
		//     iPhone app.
		if (sqlite3_config(SQLITE_CONFIG_SERIALIZED) != SQLITE_OK)
		{
			DLOG(@"sqlite could not be configured threadsafe");
			return Nil;
		}
		
		if (sqlite3_initialize() != SQLITE_OK)
		{
			DLOG(@"sqlite could not be initialized");
			return Nil;
		}
		
		if (!sqlite3_threadsafe())
		{
			DLOG(@"sqlite is not threadsafe");
			return Nil;
		}

		if (![PathHelper createMetaDataPath])
		{
			DLOG(@"failed to create metadata path");
			return Nil;
		}
		
        // DEBUG
        DLOG(@"++++++++++++++ RECREATING DATABASE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ RECREATING DATABASE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ RECREATING DATABASE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ RECREATING DATABASE DEBUG ONLY ++++++++++++++++++++++");
        DLOG(@"++++++++++++++ RECREATING DATABASE DEBUG ONLY ++++++++++++++++++++++");
        //[self recreateDatabase];
        
        
        
		if (![self createDatabase])
		{
			return Nil;
		}
		
		if (![self createLibraryTable])
		{
			return Nil;
		}
	}
	
    return self;
}

+ (void) dumpAllRecordsWithDictionaryList: (NSArray *) list
{
    if (list == Nil)
    {
        DLOG(@"error dictionary array is Nil");
        return;
    }
    
    for  (NSDictionary *record in list)
    {
        [DbManager printRecordWithDictionary:record];
    }
    
}

+ (void) printRecordWithDictionary: (NSDictionary *) dictionary
{
	if (dictionary == Nil)
	{
		DLOG(@"error dictionary is Nil");
		return;
	}
	
	if ([dictionary count] != SQL_TABLE_LIBRARY_NUM_COLUMNS)
	{
		DLOG(@"error number of columns mismatch %d", SQL_TABLE_LIBRARY_NUM_COLUMNS);
		return;
	}
	
	NSString  *fileName = [dictionary objectForKey:@"FileName"];
	NSString  *groupName = [dictionary objectForKey:@"GroupName"];
	NSInteger fileSize = [[dictionary objectForKey:@"FileSize"] integerValue];
	NSString  *dateAdded = [dictionary objectForKey:@"DateAdded"];
	NSString  *lastAccessed = [dictionary objectForKey:@"LastAccessed"];
	NSInteger totalPages = [[dictionary objectForKey:@"TotalPages"] integerValue];
	NSInteger currentPage = [[dictionary objectForKey:@"CurrentPage"] integerValue];
	NSString  *thumbNailFileName = [dictionary objectForKey:@"ThumbNailFileName"];
	NSInteger isUnread = [[dictionary objectForKey:@"IsUnread"] integerValue];
	NSInteger isDeleted = [[dictionary objectForKey:@"IsDeleted"] integerValue];
	NSInteger isValid = [[dictionary objectForKey:@"IsValid"] integerValue];
	
	DLOG(@"%@ %@ c%d %@ %@ %@ %d %d %@ %d %d %d",
		 fileName,
         groupName,
         fileSize,
		 dateAdded,
         lastAccessed,
		 totalPages,
         currentPage,
		 thumbNailFileName,
		 isUnread,
         isDeleted,
         isValid);
}

#pragma mark Database Creation

- (BOOL) createDatabase
{
	if (![PathHelper createMetaDataPath])
	{
		DLOG(@"failed to create metadata path");
		return NO;
	}
	
	if (_sqlm != Nil)
	{
		[_sqlm closeDatabase];
	}
	
	_sqlm = [[SQLiteManager alloc] initWithDatabaseNamed:SQL_DATABASE];
	
	if (_sqlm == Nil)
	{
		DLOG(@"error failed to create database");
		return NO;
	}
	
	return YES;
}

- (BOOL) recreateDatabase
{
	if (_sqlm != Nil)
	{
		[_sqlm closeDatabase];
	}
	
	if (![PathHelper deleteFileAtPath:[PathHelper getMetaDataPathWithFilename:SQL_DATABASE]])
	{
		DLOG(@"error failed to remove database file");
	}
	
	return [self createDatabase];
}

- (BOOL) createLibraryTable
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSString *query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (FileName text primary key not null,\
                       GroupName text,\
                       FileSize int DEFAULT -1,\
                       DateAdded text DEFAULT '',\
                       LastAccessed text DEFAULT '',\
                       TotalPages int DEFAULT -1,\
                       CurrentPage int DEFAULT -1,\
                       ThumbNailFileName text DEFAULT '',\
                       IsUnread int DEFAULT 1,\
                       IsDeleted int DEFAULT 0,\
                       IsValid int DEFAULT -1);", SQL_TABLE_LIBRARY];

                       
	NSError *error = [_sqlm doQuery:query];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}

- (BOOL) deleteLibraryTable
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSString *query = [NSString stringWithFormat:@"DROP TABLE %@;", SQL_TABLE_LIBRARY];
	
	NSError *error = [_sqlm doQuery:query];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}

- (BOOL) clearLibraryTable
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSString *query = [NSString stringWithFormat:@"DELETE FROM %@;", SQL_TABLE_LIBRARY];
	
	NSError *error = [_sqlm doQuery:query];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;

}

- (int) getNumberOfRowsThatAreValid
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return 0;
	}
	
	/* Note, we're using "filename", which will give us all rows. If
	   we want to get valid items, we should use "isValid".
	 */
	NSString *columnToCount = @"COUNT(FileName)";
	
	NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE IsValid=1;", columnToCount, SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	if ([results count] != 1)
	{
		DLOG(@"error, looking for one record, received %d", [results count]);
		return 0;
	}
	
	NSDictionary *record = [results objectAtIndex:0];
	
	NSNumber *numberOfRows = [record valueForKey:columnToCount];
	
	return [numberOfRows intValue];
}

#pragma mark Database Open / Close

- (BOOL) openDatabase
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSError *error = [_sqlm openDatabase];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}


- (BOOL) closeDatabase
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSError *error = [_sqlm closeDatabase];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}

#pragma Getters

- (int) getTotalPagesByFileName: (NSString *) fileName
{
    int totalPages = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return totalPages;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return totalPages;
    }
    
    totalPages = (int) [item objectForKey:@"TotalPages"];
    
    return totalPages;
}

- (int) getCurrentPageByFileName: (NSString *) fileName
{
    int currentPage = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return NO;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return currentPage;
    }
    
    currentPage = (int) [item objectForKey:@"CurrentPage"];
    
    return currentPage;
}

- (int) getIsUnreadByFileName: (NSString *) fileName
{
    int isUnread = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return isUnread;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return isUnread;
    }
    
    isUnread = (int) [item objectForKey:@"IsUnread"];
    
    return isUnread;
}

- (int) getIsDeletedByFileName: (NSString *) fileName
{
    int isDeleted = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return isDeleted;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return isDeleted;
    }
    
    isDeleted = (int) [item objectForKey:@"IsDeleted"];
    
    return isDeleted;
}

- (int) getIsValidByFileName: (NSString *) fileName
{
    int isValid = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return isValid;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return isValid;
    }
    
    isValid = (int) [item objectForKey:@"IsValid"];
    
    return isValid;
}

- (int) getFileSizeByFileName: (NSString *) fileName
{
    int fileSize = -1;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return fileSize;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return fileSize;
    }
    
    fileSize = (int) [item objectForKey:@"FileSize"];
    
    return fileSize;
}

- (NSString *) getDateAddedByFileName: (NSString *) fileName
{
    NSString *dateAdded = Nil;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return Nil;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return Nil;
    }
    
    dateAdded = (NSString *) [item objectForKey:@"DateAdded"];
    
    return dateAdded;
}

- (NSString *) getLastAccessedByFileName: (NSString *) fileName
{
    NSString *lastAccessed = Nil;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return Nil;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return Nil;
    }
    
    lastAccessed = (NSString *) [item objectForKey:@"LastAccessed"];
    
    return lastAccessed;
}

- (NSString *) getGroupNameByFileName: (NSString *) fileName
{
    NSString *groupName = Nil;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return Nil;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return Nil;
    }
    
    groupName = (NSString *) [item objectForKey:@"GroupName"];
    
    return groupName;
}

- (NSString *) getGetThumbNaileFileNameByFileName: (NSString *) fileName
{
    NSString *thumbNaileFileName = Nil;
    
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return Nil;
    }
    
    NSDictionary *item = [self getRecordByFileName:fileName];
    
    if (item==nil)
    {
        return Nil;
    }
    
    thumbNaileFileName = (NSString *) [item objectForKey:@"ThumbNaileFileName"];
    
    return thumbNaileFileName;
}


#pragma Add / Insert / Update

- (BOOL) deleteRecordWithFileName: (NSString *) fileName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	if (![self getRecordByFileName:fileName])
	{
		// Record is not there, so it's as good as deleted. At least,
		// that is the assumptions here.
		return YES;
	}
#warning I don't think you want to delete here, or do you? Maybe create a MarkForDeletion method, which will set IsValid to false and not delete.
    
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
    
	NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE FileName='%@';", SQL_TABLE_LIBRARY, cleanFileName];
		
	NSError *error = [_sqlm doQuery:query];
		
    sqlite3_free(zSQL);
    
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}

- (BOOL) setFileNameInvalid: (NSString *) fileName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	if (![self getRecordByFileName:fileName])
	{
		// Record is not there. How should updates be handled?
		return NO;
	}
	
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
    
	NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET IsValid=? WHERE FileName='%@';", SQL_TABLE_LIBRARY, cleanFileName];
	
    NSMutableArray *param = [[NSMutableArray alloc] init];
    
    NSNumber *value = [[NSNumber alloc] initWithInt:0];
    
    [param addObject:value];
    
    NSError *error = [_sqlm doUpdateQuery:query withParams:param];
    
    sqlite3_free(zSQL);
    
    if (error != Nil)
    {
        DLOG(@"error %@",[error localizedDescription]);
        return NO;
    }
	
	return YES;
}

/*
 LIMIT and OFFSET doesn't exist
- (BOOL) deleteRecordWithIndex: (int) index
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	NSString *query = [NSString stringWithFormat:@"DELETE * FROM %@ LIMIT 1 OFFSET %d;", SQL_TABLE_LIBRARY, index];
	
	NSError *error = [_sqlm doQuery:query];
	
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}
	
	return YES;
}
 */

#pragma warn Not implemented yet
- (BOOL) updateRecordWithFileName: (NSString *) fileName AndRecord: (NSDictionary *) record
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
	
	if (![self getRecordByFileName:fileName])
	{
		// Record is not there, so it's as good as deleted. At least,
		// that is the assumptions here.
		return YES;
	}
    
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
	
	NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET \
                       FileName='%@',\
                       GroupName='%@',\
                       FileSize='%@',\
                       DateAdded='%@',\
                       LastAccessed='%@',\
                       TotalPages='%@',\
                       CurrentPage='%@',\
                       ThumbNailFileName='%@',\
                       IsUnread='%@',\
                       IsDeleted='%@',\
                       IsValid='%@'\
                       WHERE FileName='%@';",
                       SQL_TABLE_LIBRARY,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName,
                       cleanFileName];
    
    sqlite3_free(zSQL);
	
//	NSError *error = [_sqlm doUpdateQuery:query withParams:];
/*
	if (error != Nil)
	{
		DLOG(@"error %@",[error localizedDescription]);
		return NO;
	}*/
	
	return YES;
}

- (BOOL) insertRecordWithName: (NSString *) fileName
				 AndGroupName: (NSString *) groupName
				  AndFileSize: (NSInteger)  fileSize
			     AndDateAdded: (NSString *) dateAdded
			  AndLastAccessed: (NSString *) lastAccessed
				AndTotalPages: (NSInteger)  totalPages
			   AndCurrentPage: (NSInteger)  currentPage
		 AndThumbNailFileName: (NSString *) thumbNailFileName
				  AndIsUnread: (NSInteger)  isUnread
				 AndIsDeleted: (NSInteger)  isDeleted
				   AndIsValid: (NSInteger)  isValid
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return NO;
	}
    
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
	/*
    NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (FileName, GroupName, FileSize, DateCreated, DateModified, DateAccessed, TotalPages, CurrentPage, ThumbNailFileName, IsUnread, IsDeleted, IsValid) values ('%@','%@','%ld','%@','%@','%@','%ld','%ld','%@','%ld','%ld','%ld');",
                        SQL_TABLE_LIBRARY,
                        cleanFileName,
                        groupName,
                        (long)fileSize,
                        dateAdded,
                        lastAccessed,
                        (long)totalPages,
                        (long)currentPage,
                        thumbNailFileName,
                        (long)isUnread,
                        (long)isDeleted,
                        (long)isValid
						];*/
    
    /* This works and creats NULL values in table, but then NULL values aren't valid in an NSDictionary, so doesn't work.*/
    NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (FileName, GroupName, FileSize, IsValid) values ('%@','%@','%ld','%ld');",
                        SQL_TABLE_LIBRARY,
                        cleanFileName,
                        groupName,
                        (long)fileSize,
                        (long)isValid
                        ];
	
    sqlite3_free(zSQL);
    
	// Create an empty record first
	//NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (FileName) values ('%@');", SQL_TABLE_LIBRARY, fileName];
	
	NSError *error = [_sqlm doQuery:sqlStr];
	
	if (error != nil)
	{
		NSLog(@"Error: %@",[error localizedDescription]);
	}

	// Write whatever records are not NULL
	
	return YES;
}

- (BOOL) insertRecordWithName: (NSString *) fileName
                 AndGroupName: (NSString *) groupName
                  AndFileSize: (NSInteger)  fileSize
                   AndIsValid: (NSInteger)  isValid
{
    if (_sqlm == Nil)
    {
        DLOG(@"error sqlm is Nil");
        return NO;
    }
    
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
    
    /* This works and creats NULL values in table, but then NULL values aren't valid in an NSDictionary, so doesn't work.*/
    NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (FileName, GroupName, FileSize, IsValid) values ('%@','%@','%ld','%ld');",
                        SQL_TABLE_LIBRARY,
                        cleanFileName,
                        groupName,
                        (long)fileSize,
                        (long)isValid
                        ];
    
    sqlite3_free(zSQL);
    
    // Create an empty record first
    //NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (FileName) values ('%@');", SQL_TABLE_LIBRARY, fileName];
    
    NSError *error = [_sqlm doQuery:sqlStr];
    
    if (error != nil)
    {
        NSLog(@"Error: %@",[error localizedDescription]);
    }
    
    // Write whatever records are not NULL
    
    return YES;
}

#pragma mark Queries

-(NSDictionary *) getRecordByFileName: (NSString *) fileName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
    char *zSQL = sqlite3_mprintf("%q", [fileName UTF8String]);
    
    NSString *cleanFileName = [NSString stringWithUTF8String:zSQL];
    
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE FileName='%@';", SQL_TABLE_LIBRARY, cleanFileName];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
    sqlite3_free(zSQL);
    
	if ([results count] != 1)
	{
		DLOG(@"error, looking for %@, received %d", fileName, [results count]);
		return Nil;
	}
	
	NSDictionary *record = [results objectAtIndex:0];
	
	return record;
}

- (NSDictionary *) getRecordByIndex: (int) index
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	//NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 1 OFFSET %d;", SQL_TABLE_LIBRARY, index];
	
	// Ordering By ASC for now. Doing this temporarily until we add other sorting methods.
    
	// select * from "library" where IsValid='1' ORDER BY FileName COLLATE NOCASE ASC;
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE IsValid=1 ORDER BY FileName COLLATE NOCASE ASC LIMIT 1 OFFSET %d;", SQL_TABLE_LIBRARY, index];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	if ([results count] != 1)
	{
		DLOG(@"error, looking for one record, received %d", [results count]);
		return Nil;
	}
	
	NSDictionary *record = [results objectAtIndex:0];
	
	return record;
}

- (NSArray *) getAllRecordsInvalid
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE IsValid=0;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsUnsorted
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE IsValid=1;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByFileNameAndSortByAlphaAscending
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE IsValid=1 ORDER BY FileName COLLATE NOCASE ASC;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByFileNameAndSortByAlphaAscendingCaseSensitive
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE IsValid=1 ORDER BY FileName ASC;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByFileNameAndSortByAlphaDescending
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE IsValid=1 ORDER BY FileName COLLATE NOCASE DESC;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByFileNameAndSortByAlphaDescendingCaseSensitive
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
		
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE IsValid=1 ORDER BY FileName DESC;", SQL_TABLE_LIBRARY];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaAscending: (NSString *) groupName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE GroupName='%@' AND IsValid=1 ORDER BY FileName COLLATE NOCASE ASC;",
					   SQL_TABLE_LIBRARY,
					   groupName];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaAscendingCaseSensitive: (NSString *) groupName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE GroupName='%@' AND IsValid=1 ORDER BY FileName ASC;",
					   SQL_TABLE_LIBRARY,
					   groupName];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaDescending: (NSString *) groupName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE GroupName='%@' AND IsValid=1 ORDER BY FileName COLLATE NOCASE DESC;",
					   SQL_TABLE_LIBRARY,
					   groupName];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

- (NSArray *) getAllRecordsByGroupNameAndSortByAlphaDescendingCaseSensitive: (NSString *) groupName
{
	if (_sqlm == Nil)
	{
		DLOG(@"error sqlm is Nil");
		return Nil;
	}
	
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE GroupName='%@' AND IsValid=1 ORDER BY FileName DESC;",
					   SQL_TABLE_LIBRARY,
					   groupName];
	
	NSArray *results = [_sqlm getRowsForQuery:query];
	
	return results;
}

@end
