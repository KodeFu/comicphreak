//
//  DirectoryManager.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 1/28/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

#import "DirectoryManager.h"
#import "DbManager.h"
#import "PathHelper.h"
#import "Debug.h"

@interface DirectoryManager()
{
@private
    NSLock *_directoryAccessLock;
    BOOL _killDirectoryMonitorThread;
}

@end

@implementation DirectoryManager

+ (DirectoryManager *) sharedInstance
{
    static DirectoryManager *sharedInstance = Nil;
    static dispatch_once_t onceToken = 0;
    
	dispatch_once(&onceToken, ^{
			sharedInstance = [[self alloc] init];
    });
	
    return sharedInstance;
}

- (id) init
{
    self = [super init];
	
    if (self)
	{
        // Create the directory lock
		_directoryAccessLock = [[NSLock alloc] init];
        
        _killDirectoryMonitorThread = NO;
        [self _startDirectoryMonitorThread];
	}
	
    return self;
}

- (void) dealloc
{
    _killDirectoryMonitorThread = YES;

}

#pragma mark Meta Data

// Given a comic filename, get the groupname. If the groupname exists return the index
// of the group number. If it doesn't exist, add the new group and return the new group's
// number.
- (NSString *) getGroupFromFileName: (NSString *) fileName
{
	// Delete path extension
	NSString *str = [[fileName lowercaseString] stringByDeletingPathExtension];
    
	// Trim preceding characters by finding the first lower case character and substring it
	NSRange firstAlpha = [str rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]];
	NSString *nextString = [str substringFromIndex:firstAlpha.location];
	
	// Turn these special characters often used for spacing and turn them into spaces
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"." withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"," withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"-" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"#" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"~" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"^" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"!" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"=" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"*" withString:@" "];
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
	
	// Remove apostrophies, sorry
	nextString =  [nextString stringByReplacingOccurrencesOfString:@"'" withString:@""];
    
	// Split the string into components
	NSArray *strComponents = [nextString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSString *tmpComponent;
	NSString *finalString = @"";
	bool bIsFirstComponent = true;
	for (tmpComponent in strComponents)
	{
		// Remove spaces
		tmpComponent = [tmpComponent stringByReplacingOccurrencesOfString:@" " withString:@""];
		
		// Skip spaces
		if ([tmpComponent length] == 0)
		{
			continue;
		}
		
 		// Look for non-lower case alphabet characters
		firstAlpha = [tmpComponent rangeOfCharacterFromSet:[[NSCharacterSet lowercaseLetterCharacterSet] invertedSet]];
		
		if (firstAlpha.location == NSNotFound)
		{
			// Prepend space after first component
			if (!bIsFirstComponent)
			{
				finalString = [finalString stringByAppendingFormat:@" "];
			}
			else
			{
				bIsFirstComponent = false;
			}
			
			// Append the compent, capitalized
			finalString = [finalString stringByAppendingFormat:@"%@", [tmpComponent capitalizedString] ];
		}
		else
		{
			// Found a non-lower case alphebet component, skip the rest of the name.
			break;
		}
	}
    
	// If the string is empty, which can mean there are mixed letters and numbers all
	// concatenated together so they can't be split up (maybe do this in the future?),
	// then use the name as the final string.
	if ([finalString length]==0)
	{
		
		finalString = [fileName stringByDeletingPathExtension];
	}
	
	return finalString;
}


#pragma mark Directory Change

- (NSArray *) getDirectorySnapshot
{
    NSArray *contents = [PathHelper getDocumentsListingsNoDotFiles];
    
	// Nice code and alternative to alloc/init of NSMutableArray. With this code, no release necessary
	// since it's part of the autorelease pool and you never allocated it.
    NSMutableArray *directoryMetadata = [NSMutableArray array];
    
    for (NSString *fileName in contents)
	{
        @autoreleasepool
		{
            NSString *filePath = [PathHelper getDocumentsPathWithFilename:fileName];
            
			// Get the file size
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
			
            // The fileName and fileSize will be our hash key
            NSString *fileHash = [NSString stringWithFormat:@"%@%d", fileName, fileSize];
            
			// Add it to our metadata list ("<fileName><fileSize>").
            [directoryMetadata addObject:fileHash];
        }
    }
	
    return directoryMetadata;
}

- (BOOL) IsDirectoryStable
{
	NSArray *currDirectory;
	bool directoryTimedOut = NO;
	
	// Time out can happen on a long sync where there is much churn in the file system. This is fine,
    // but I get nervous about staying in a loop indefinitely, unless it's a thread.
	int timeOut = 1 * 60 * 5;    // 1 sec * 60 sec/min * 5 min
    int waitInterval = 2 * 1.0;  // 2 sec
	int waitCount = 0;
	
	// Get the name/size hash of directory
	currDirectory = [self getDirectorySnapshot];
    
	// Wait for directory to stabalize
	while (!directoryTimedOut)
	{
		// Sleep some
		[NSThread sleepForTimeInterval:waitInterval];
		
		// Take a directory snapshot
		NSArray *tempDirectory = [self getDirectorySnapshot];
		
		if ([tempDirectory isEqualToArray:currDirectory])
		{
			// Yep, stable. File sizes are stable.
			return YES;
		}
		else
		{
            // Directory is not stable. Either the number of entries differ or
            // the file size differs.
            if (waitCount++>timeOut)
            {
                DLOG(@"bailing, try again later...");
                directoryTimedOut = YES;
            }
            
            // Save the new "current" directory
            currDirectory = [NSArray arrayWithArray:tempDirectory];
		}
	}
	
	return NO;
}


/*****************************************************************************************
 
 Directory Sync Scenarios
 
 [FileSystem]
  1. Scenario - Comics on filesystem, but not in database.
    -- Get list from file system.
        -- If they are not in database, add them with IsValid=1. Update view!!!
        -- If they are in database, do not add them. Do nothing.
            -- if you do, you will mess with the meta data, like Isvalid flag.
 
 [Database]
 2. Scenario - IsValid comics in database
    -- If on filesystem, do nothing. All's good.
    -- If not on filesystem, set IsInvalid=0. Update view!!!
 
 [Clean-up]
 1. Scenario - Invalid comics in database, but comics on filesystem.
    -- Delete comic on filesystem. Remove entry in database. Update view!!!
 
 2. Scenario - Invalid comics in database, but comics not on filesystem.
    -- Remove entry in database.
 
 Order of Sync'ing -- Doesn't really matter because the UI is locked.
 1. First check the file-system. This will add items to the database and make them 
    available or invalidate the entries. Either way, the end-user will not have an 
    up-to-date view of the current set of comic files. Most complex w/user impacat.
 2. Database
 3. Cleanup
 
 But, we have three update views? Can we do it all in one function? We do not want to 
 update view three times.
 
 SynchronizeDatabaseAndFileSystem()
    UpdateFileSystemView
    UpdateDatabaseView
    CleanupFileSystem
 
 ShouldSync()
    if (IsFileSystemOutOfSync or IsDatabaseOutOfSync)
      return TRUE
 
 IsFileSystemStable()
    While !(FileSystemNotStable) return TRUE
 
 DirectoryMonitorThread
    While ShouldSync
        LOCK
        IsFileSystemStable
        SynchronizeDatabaseAndFileSystem
        UNLOCK
 
 *****************************************************************************************/


#pragma mark Sync Checks

- (BOOL) IsFileSystemOutOfSync
{
	// Get filesystem directory
	NSArray *directoryOfComics = [PathHelper getDocumentsListingsNoDotFiles];
    
	// Query database for each file
	for (NSString *comicName in directoryOfComics)
	{
		// Get the record from the database (whether valid or invalid)
		NSDictionary *comicRecord = [[DbManager sharedInstance] getRecordByFileName:comicName];
		
		// Check if comic is not in database
		if (comicRecord == Nil)
		{
			DLOG(@"%@ is not in database, need to sync database", comicName);
			return YES;
		}
		
		if (comicRecord != Nil)
		{
            // Get filesize of filesystem file
            NSString *filePath = [PathHelper getDocumentsPathWithFilename:comicName];
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
			NSInteger fileSize = [[fileAttributes valueForKey:NSFileSize] intValue];
            
            // Get filesize of database file
			NSInteger comicRecordFilesize = [[comicRecord valueForKey:@"FileSize"] intValue];
            
            // Compare the sizes
			if (fileSize != comicRecordFilesize)
			{
				DLOG(@"%@ has a different filesize (%d), need to sync database (%d)", comicName, fileSize, comicRecordFilesize);
				return YES;
			}
		}
    }
    
    return NO;
}

- (BOOL) IsDatabaseOutOfSync
{
    // Check if all IsValid=1 entries in the database are also in the filesystem.
    // If they are not on the filesystem, we need to sync.
    NSArray *validFiles = [[DbManager sharedInstance] getAllRecordsUnsorted];
    
    for (int i=0; i<[validFiles count]; i++)
    {
        NSDictionary *record = [validFiles objectAtIndex:i];
        
        NSString *fileName = [record objectForKey:@"FileName"];
        
        BOOL fileExists = [PathHelper fileExistsAtPath:[PathHelper getDocumentsPathWithFilename:fileName]];
        if (!fileExists)
        {
            DLOG(@"%@ doesn't exist on filesystem but exists in database, need to sync", fileName);
            return YES;
        }
    }
    
    return NO;
    
}

- (BOOL) ShouldSync
{
    if ([self IsFileSystemOutOfSync] || [self IsDatabaseOutOfSync])
    {
        DLOG(@"need to sync...");
        return YES;
    }
    
    return NO;
}

#pragma mark Sychronization

- (void) SynchronizeFileSystem
{
    // Get directory of files
    NSArray *directoryOfComics = [PathHelper getDocumentsListingsNoDotFiles];
    
    for (NSString *fileName in directoryOfComics)
    {
        // Get filesize of filesystem file
        NSString *filePath = [PathHelper getDocumentsPathWithFilename:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSInteger fileSize = [[fileAttributes valueForKey:NSFileSize] intValue];
        
        // Get today's date for date added
        //NSDate now = [NSDate
        
        
        // Add groupname
        NSString *groupName = [self getGroupFromFileName:fileName];
        
        
        // Add each filename, filesize to the database, IsValue=true
        [[DbManager sharedInstance] insertRecordWithName:fileName AndGroupName:groupName AndFileSize:fileSize AndDateCreated:@"" AndDateModified:@"" AndDateAccessed:@"" AndTotalPages:0 AndCurrentPage:0 AndThumbNailFileName:@"" AndIsUnread:0 AndIsDeleted:0 AndIsValid:1];
        
        // !!! Add valid sizes, data modfied/access, created, etc here.
        
        // FIXME: You may be clobbering over prior metadata like file size. This is ok if the file size is different.
        // More work here!!!
        
    }
}

- (void) SynchronizeDatabase
{
    // Check if all IsValid=1 entries in the database are also in the filesystem.
    // If they are not on the filesystem, we need to sync.
    NSArray *validFiles = [[DbManager sharedInstance] getAllRecordsUnsorted];
    
    for (int i=0; i<[validFiles count]; i++)
    {
        NSDictionary *record = [validFiles objectAtIndex:i];
        
        NSString *fileName = [record objectForKey:@"FileName"];
        
        BOOL fileExists = [PathHelper fileExistsAtPath:[PathHelper getDocumentsPathWithFilename:fileName]];
        if (!fileExists)
        {
            //DLOG(@"setting %@ to invalid", fileName);
            [[DbManager sharedInstance] setFileNameInvalid:fileName];
        }
    }
}

- (void) CleanupFileSystemAndDatabase
{
    // Check if all IsValid=1 entries in the database are also in the filesystem.
    // If they are not on the filesystem, we need to sync.
    NSArray *inValidFiles = [[DbManager sharedInstance] getAllRecordsInvalid];
    
    for (int i=0; i<[inValidFiles count]; i++)
    {
        NSDictionary *record = [inValidFiles objectAtIndex:i];
        
        NSString *fileName = [record objectForKey:@"FileName"];
        
        BOOL fileExists = [PathHelper fileExistsAtPath:[PathHelper getDocumentsPathWithFilename:fileName]];
        if (fileExists)
        {
            [PathHelper deleteFileAtDocumentsPathWithName:fileName];
        }
        
        [[DbManager sharedInstance] deleteRecordWithFileName:fileName];
    }
}

#pragma mark Directory Monitor Thread

- (void) _startDirectoryMonitorThread
{
	// Create the thumbnail thread
    [NSThread detachNewThreadSelector:@selector(GetDirectoryThreadWithObject:) toTarget:self withObject:self];
}

- (void) GetDirectoryThreadWithObject: (id) directoryManager
{
    @autoreleasepool
    {
        while (!_killDirectoryMonitorThread)
        {
            @autoreleasepool
            {
                if (![self IsDirectoryStable])
                {
                    continue;
                }

                [_directoryAccessLock lock];
                
                if ([directoryManager IsFileSystemOutOfSync] || [self IsDatabaseOutOfSync])
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"START_SYNC" object:Nil];
                    
                    [self SynchronizeFileSystem];
                    [self SynchronizeDatabase];
                    [self CleanupFileSystemAndDatabase];

                    [[NSNotificationCenter defaultCenter] postNotificationName:@"STOP_SYNC" object:Nil];
                }
                
                [_directoryAccessLock unlock];
                
                [NSThread sleepForTimeInterval:2.0];
            }
        }
    }

}


@end
