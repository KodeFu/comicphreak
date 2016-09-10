//
//  PathHelper.m
//  Comic Phreak
//
//  Created by Mudit Vats on 6/19/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import "PathHelper.h"
#import "Debug.h"

@implementation PathHelper

/****************************************************************************
 Path and Filename Methods
 ****************************************************************************/

+ (NSString *) getDocumentsPath
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *) getMetaDataPath
{
	return [[self getDocumentsPath] stringByAppendingPathComponent:@".data"];
}

+ (NSString *) getDocumentsPathWithFilename:(NSString *) fileName
{
	// Add the file to the path, but change to plist
	NSString *tmpPath = [[self getDocumentsPath] stringByAppendingPathComponent:fileName];
	
	return tmpPath;
}

+ (NSString *) getMetaDataPathWithFilename:(NSString *) fileName
{
	// Add the file to the path, but change to plist
	NSString *tmpPath = [[self getMetaDataPath] stringByAppendingPathComponent:[fileName stringByAppendingString:@".plist"]];
	
	return tmpPath;
}

// Just delete the file from the directory. When the thread runs, it will pick up the
// change and that will be updated on the lists.
+ (BOOL) deleteFileAtDocumentsPathWithName:(NSString *) fileName
{
	bool success = NO;
	
	if (fileName != Nil)
	{
		NSString *filePath = [PathHelper getDocumentsPathWithFilename:fileName];
		success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:Nil];
	}
	
	return success;
}

+ (BOOL) deleteFileAtMetaDataPathWithName:(NSString *) fileName
{
	bool success = NO;
	
	if (fileName != Nil)
	{
		NSString *filePath = [PathHelper getMetaDataPathWithFilename:fileName];
		success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:Nil];
	}
	
	return success;
}

+ (BOOL) deleteFileAtPath:(NSString *) path
{
	bool success = NO;
	
	if (path != Nil)
	{
		success = [[NSFileManager defaultManager] removeItemAtPath:path error:Nil];
	}
	
	return success;
}


+ (NSArray *) getDirectoryListingAtPath: (NSString *) path
{
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path  error:Nil];
}

+ (NSArray *) getDocumentsListing
{
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getDocumentsPath]  error:Nil];
}

+ (NSArray *) getDocumentsListingsNoDotFiles
{
    // Get filesystem directory
	NSArray *directoryOfComics = [PathHelper getDocumentsListing];
	
    // Filesystem array without dot files
    NSMutableArray *directoryOfComicsNoDotFiles = [[NSMutableArray alloc] init];
    
	// Query database for each file
	for (NSString *comicName in directoryOfComics)
	{
		NSString *filePath = [PathHelper getDocumentsPathWithFilename:comicName];
		
		// Ignore directories
		BOOL isDir = NO;
		BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
		if (fileExists && isDir)
		{
			continue;
		}
        
        // Ignore dot files, which are typcially system files
        if ([comicName characterAtIndex:0] == '.')
        {
            continue;
        }
        
        [directoryOfComicsNoDotFiles addObject:comicName];
    }
    NSArray *newArray = [NSArray arrayWithArray:directoryOfComicsNoDotFiles];
    return newArray;
}

+ (NSArray *) getMetaDataListing
{
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getMetaDataPath]  error:Nil];
}

+ (BOOL) fileExistsAtPath: (NSString *) path
{
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


+ (BOOL) createMetaDataPath
{
	BOOL success = NO;
	
	NSString *tmpPath = [PathHelper getMetaDataPath];
	
	if ([PathHelper fileExistsAtPath:tmpPath])
	{
		return true;
	}
	
	// Create the .data directory
	success = [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath
										withIntermediateDirectories:YES
														 attributes:Nil
															  error:NULL];
	if (!success)
	{
		DLOG(@"could not create directory %@", tmpPath);
	}
	
	return success;
}

@end
