//
//  PathHelper.h
//  Comic Phreak
//
//  Created by Mudit Vats on 6/19/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathHelper : NSObject

// Path Manipulation
+ (NSString *) getDocumentsPath;
+ (NSString *) getDocumentsPathWithFilename:(NSString *) fileName;
+ (NSString *) getMetaDataPath;
+ (NSString *) getMetaDataPathWithFilename:(NSString *) fileName;

// File Deletion
+ (BOOL) deleteFileAtDocumentsPathWithName:(NSString *) fileName;
+ (BOOL) deleteFileAtMetaDataPathWithName:(NSString *) fileName;
+ (BOOL) deleteFileAtPath:(NSString *) path;

// Get Directory Listing
+ (NSArray *) getDocumentsListing;
+ (NSArray *) getDocumentsListingsNoDotFiles;
+ (NSArray *) getMetaDataListing;
+ (NSArray *) getDirectoryListingAtPath: (NSString *) path;

// File Existance
+ (BOOL) fileExistsAtPath: (NSString *) path;

// Create Meta Data Path
+ (BOOL) createMetaDataPath;

@end
