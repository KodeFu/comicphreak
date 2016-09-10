//
//  Comic.m
//  SplitDemo
//
//  Created by Mudit Vats on 3/22/12.
//  Copyright 2012 HealthPro Solutions, LLC. All rights reserved.
//

#import "Comic.h"
#import "Debug.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"
// #import "SettingsManager.h"

/****************************************************************************
 Globals
 ****************************************************************************/

// HACK USING GLOBAL
int globalPage = 0;

/****************************************************************************
 Interface Methods
 ****************************************************************************/

@implementation Comic
{
	int comicType;
}

/****************************************************************************
 Init Methods
 ****************************************************************************/

- (id)init
{
    self = [super init];
	
    if (self) {
		// Do some initializization...

		// Dude, update the initWithFileName... :-)
	}
	
    return self;
}

- (id) initWithFileName: (NSString *) name
{
	self = [super init];
	
    if (self) {
		// Save the comic name
		self.comicFileName = name; // Shouldn't need to retain, since it's a copy - [name retain];
		self.isValidComic = NO;
		
		NSMutableArray *tmpDirectory = [[NSMutableArray alloc] init];
		self.directoryOfPages = tmpDirectory;
        tmpDirectory = Nil;
//		[tmpDirectory release];
	}
	
	// Open/create status file
	
    return self;
}

- (void) dealloc
{	
//	[self.comicFileName release];
	
	[self.directoryOfPages removeAllObjects];
//	[self.directoryOfPages release];

    //[super dealloc];
}

/****************************************************************************
 Comic Methods - External
 ****************************************************************************/

// Bug is that openComic is calling _openXXComicPage, but doesn't need to.
// We should initialze first...
- (BOOL) openComic
{
	// FIXME: Check for currentPage bounds since we're now setting this before
	if (_comicCurrentPage <0) {
		// Since we accessed it, it is no longer unread
		self.comicCurrentPage = 0;
	}
	
	// FIXME: Should we save total pages in the plist?
	_comicTotalPages = 0;

	if (_comicFileName == Nil) {
		DLOG(@"can't open comic because comic name is Nil");
		_isValidComic = NO;
	}
	
	NSString *localName = [_comicFileName uppercaseString];
	
	if (([[localName pathExtension] compare:@"CBZ"] == NSOrderedSame) || 
		([[localName pathExtension] compare:@"ZIP"] == NSOrderedSame)) {
		
		comicType = 0;
		_isValidComic = [self _getZipComicInfo];
		
		if (!_isValidComic) {
			// Check if it's a CBZ instead
			comicType = 1;
			_isValidComic = [self _getRarComicInfo];
		}
		
	} else if (([[localName pathExtension] compare:@"CBR"] == NSOrderedSame) || 
			   ([[localName pathExtension] compare:@"RAR"] == NSOrderedSame)) {

		comicType = 1;
		_isValidComic = [self _getRarComicInfo];
		
		if (!_isValidComic) {
			// Check if it's a CBR instead
			comicType = 0;
			_isValidComic = [self _getZipComicInfo];
		}
		
	} else {
		DLOG(@"unknown file extension %@", [localName pathExtension]);
		comicType = -1;
	}

	return _isValidComic;
}

- (UIImage *) getImageAtIndex: (int) index
{
	if ((index>=0) && (index<_comicTotalPages))
	{
		// Update the curren comic page
		self.comicCurrentPage = index;
		
		switch (comicType) {
			case 0: // Zip
				return [self _openZipComicPage:index];
				break;
			case 1: // Rar
				return [self _openRarComicPage:index];
				break;
				
			default:
				break;
		}
		
	}
	
	return Nil;
}

/****************************************************************************
 Comic Methods - Internal
 ****************************************************************************/

- (BOOL) _getZipComicInfo
{
	ZipFile *zipArchive;
	FileInZipInfo *zipInfo = Nil;
	int pageIndex;
	BOOL err = NO;
	
	// Check the file type; make sure it's a ZIP file
	FILE *fp = fopen(_comicFileName.UTF8String, "rb");
	
	if (fp) {
		char a = toupper(fgetc(fp));
		char b = toupper(fgetc(fp));
		char c = toupper(fgetc(fp));
		char d = toupper(fgetc(fp));
		fclose(fp);
		
		/* PK.. */
		if ((a!=0x50) && (b!=0x4b) && (c!=0x03) && (d!=0x04)) {
			//DLOG(@"%@ is not a ZIP file!", [_comicFileName lastPathComponent]);
			return NO;
		}
	} else {
		// File does not exist; this can happen during an iTune file sync
		return NO;
	}
	
	// Open the comic
	zipArchive = [[ZipFile alloc] initWithFileName:_comicFileName mode:ZipFileModeUnzip];
	
	if (zipArchive == Nil) 	{
		DLOG(@"error couldn't allocate zip file");
		return NO;
	}
	
	if (![zipArchive isUnzipFileInitialized])
    {
        zipArchive = Nil;
//		[zipArchive release];
		DLOG(@"error couldn't open zip file");
		return NO;
	}

	// Get the file list
	NSMutableArray *filenameArray = [[NSMutableArray alloc] init];
	[zipArchive goToFirstFileInZip];
	for (pageIndex=0; pageIndex<[zipArchive numFilesInZip]; pageIndex++)  {
		zipInfo = [zipArchive getCurrentFileInZipInfo];
		[filenameArray addObject:zipInfo.name];
		[zipArchive goToNextFileInZip];
	}

	// Alpha sort
	[filenameArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	// Check if the file is a picture format
	for (int i=0; i<[filenameArray count]; i++) {
		NSString *fileName = [filenameArray objectAtIndex:i];
		fileName = [fileName uppercaseString];
		
		NSString *fileExt = [fileName pathExtension];
		
		if (([fileExt compare:@"JPG" ] == NSOrderedSame) || 
			([fileExt compare:@"JPEG"] == NSOrderedSame) ||
			([fileExt compare:@"PNG" ] == NSOrderedSame) || 
			([fileExt compare:@"TIF" ] == NSOrderedSame) ||
			([fileExt compare:@"TIFF"] == NSOrderedSame) || 
			([fileExt compare:@"BMP" ] == NSOrderedSame)) {

			// Add the page, since it seems valid
			[self.directoryOfPages addObject:[filenameArray objectAtIndex:i]];
		}
	}
	
	// Done with the filenameArray
	[filenameArray removeAllObjects];
    filenameArray =  Nil;
//	[filenameArray release];
    
	// Cache the number of files in archive, which are the pages
	_comicTotalPages = [_directoryOfPages count];
	
	err = YES;
	
DONE:
	[zipArchive close];
    zipArchive = Nil;
//	[zipArchive release];
	
	return err;
}

/* It would be great to have an atomic page read for the comic.
 * Seek to the page and then return the UIImage.
 */
- (UIImage *) _openZipComicPage: (int) page
{
	BOOL foundComic = NO;
	ZipFile *zipArchive;
	NSMutableData *uncompressedData = Nil;
	FileInZipInfo *zipInfo = Nil;
	ZipReadStream *readFile = Nil;
	int bytesRead = 0;
	UIImage *comicPageImage = Nil;
	
	// Check the file type; make sure it's a ZIP file
	FILE *fp = fopen(_comicFileName.UTF8String, "rb");
	
	if (fp) {
		// File exists
	} else {
		// File does not exist; this can happen during an iTune file sync
		return [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"error_bad_page" ofType:@"png"]];;
	}
	
	// Open the comic
	zipArchive = [[ZipFile alloc] initWithFileName:_comicFileName mode:ZipFileModeUnzip];
	
	if (zipArchive == Nil) 	{
		DLOG(@"error couldn't allocate zip file");
		return Nil;
	}
	
	if (![zipArchive isUnzipFileInitialized]) {
        zipArchive = Nil;
//		[zipArchive release];
		DLOG(@"error couldn't open zip file");
		return Nil;
	}
	
	// Find the file
	// FIXME: Need to be more efficient about this. Like, do it once and cache
	// the list
	foundComic = [zipArchive locateFileInZip:[_directoryOfPages objectAtIndex:page]];
	if (!foundComic) {
		DLOG(@"coudn't find comic at page %d / total pages %d", page, _comicTotalPages)
		goto DONE;
	}
	
	// Get the current file
	zipInfo = [zipArchive getCurrentFileInZipInfo];
	readFile = [zipArchive readCurrentFileInZip];
		
	// Setup a buffer to hold the uncompressed data
	uncompressedData = [[NSMutableData alloc] initWithLength:zipInfo.length];
	
	if (uncompressedData == Nil) {
		DLOG(@"couldn't allocate memory to uncompress data");
		goto DONE;
	}
		
	// Save the uncompressed data
	bytesRead = [readFile readDataWithBuffer:uncompressedData];
	[readFile finishedReading];
	
	if (bytesRead!=zipInfo.length) 	{
		DLOG(@"file read mismatch, bad read on page %d", page);
		if ((bytesRead>0) && (uncompressedData!=Nil)) {
            uncompressedData = Nil;
//			[uncompressedData release];
		}
		goto DONE;
	}

	// NOTE, the UIImage below is not autoreleased since we access cross thread. Make sure
	// the object gets release by manually calling [object release]
	comicPageImage = [[UIImage alloc] initWithData:uncompressedData];
	
	// Deallocate the uncompressedData
//	[uncompressedData release];
	uncompressedData = Nil;
		
	if (comicPageImage== Nil) {
		// NOTE, the UIImage below is not autoreleased since we access cross thread. Make sure
		// the object gets release by manually calling [object release]
		comicPageImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"error_bad_page" ofType:@"png"]];
		DLOG(@"can't create UIImage from zip data on page %d - using default", page);
		goto DONE;
	}
	
DONE:
	[zipArchive close];
    zipArchive = Nil;
//	[zipArchive release];
	
	return comicPageImage;
}

- (BOOL) _getRarComicInfo
{
	Unrar4iOS *rarArchive;
	NSArray *rarFiles;
	BOOL err = NO;
	
	// Check the file type; make sure it's a RAR file
	FILE *fp = fopen(_comicFileName.UTF8String, "rb");
	
	if (fp) {
		// File exists
		char a = toupper(fgetc(fp));
		char b = toupper(fgetc(fp));
		char c = toupper(fgetc(fp));
		char d = toupper(fgetc(fp));
		fclose(fp);
		
		if ((a!='R') && (b!='A') && (c!='R') && (d!='!')) {
			//DLOG(@"%@ is not a RAR file!", [_comicFileName lastPathComponent]);
			return NO;
		}
	} else {
		// File does not exist; this can happen during an iTune file sync
		return NO;
	}
	
	// Open the comic
	rarArchive = [[Unrar4iOS alloc] init];	
	
	if (rarArchive == Nil) 	{
		DLOG(@"error couldn't allocate rar file");
		return NO;
	}
	
	BOOL ok = [rarArchive unrarOpenFile:_comicFileName];
	
	if (!ok) {
		DLOG(@"error couldn't open file");
		goto DONE;
	}
	
	// Get the number of files in archive
	rarFiles = [rarArchive unrarListFiles];
	
	// Alphabetize the list
	rarFiles = [rarFiles sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	// Check if the file is a picture format
	for (int i=0; i<[rarFiles count]; i++) {
		NSString *fileName = [rarFiles objectAtIndex:i];
		fileName = [fileName uppercaseString];
		
		NSString *fileExt = [fileName pathExtension];
		
		if (([fileExt compare:@"JPG" ] == NSOrderedSame) || 
			([fileExt compare:@"JPEG"] == NSOrderedSame) ||
			([fileExt compare:@"PNG" ] == NSOrderedSame) || 
			([fileExt compare:@"TIF" ] == NSOrderedSame) ||
			([fileExt compare:@"TIFF"] == NSOrderedSame) || 
			([fileExt compare:@"BMP" ] == NSOrderedSame)) {
			
			// Add the page, since it seems valid
			[self.directoryOfPages addObject:[rarFiles objectAtIndex:i]];
		}
	}
	
	_comicTotalPages = [_directoryOfPages count];
	
	// Success
	err = YES;
	
DONE:
	[rarArchive unrarCloseFile];
    rarArchive = Nil;
//	[rarArchive release];
	
	return err;
}

- (UIImage *) _openRarComicPage: (int) page
{
	Unrar4iOS *rarArchive;
	UIImage *comicPageImage = Nil;
	NSData *uncompressedData = Nil;
	
	// Check the file type; make sure it's a RAR file
	FILE *fp = fopen(_comicFileName.UTF8String, "rb");
	
	if (fp) {
		// File exists
		fclose(fp);
	} else {
		// File does not exist; this can happen during an iTune file sync
		return [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"error_bad_page" ofType:@"png"]];;
	}
	
	// Open the comic
	rarArchive = [[Unrar4iOS alloc] init];	
	if (rarArchive == Nil) 	{
		DLOG(@"error couldn't allocate rar file");
		return Nil;
	}
	
	BOOL ok = [rarArchive unrarOpenFile:_comicFileName];
	if (!ok) {
		DLOG(@"error couldn't open file");
		goto DONE;
	}
	
	// Setup a buffer to hold the uncompressed data
	uncompressedData = [rarArchive extractStream:[_directoryOfPages objectAtIndex:page]];
	
	// NOTE, the UIImage below is not autoreleased since we access cross thread. Make sure
	// the object gets release by manually calling [object release]
	comicPageImage = [[UIImage alloc] initWithData:uncompressedData];
		
	// Deallocate the uncompressedData
	// Note, we do not deallocate because NSData create. As such, it should
	// be resposible for the deallocation.
	uncompressedData = Nil;

	if (comicPageImage == Nil) {
		// NOTE, the UIImage below is not autoreleased since we access cross thread. Make sure
		// the object gets release by manually calling [object release]
		comicPageImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"error_bad_page" ofType:@"png"]];
		DLOG(@"can't create UIImage from rar data on page %d - using default", page);
		goto DONE;
	}
	
DONE:
	[rarArchive unrarCloseFile];
    rarArchive =  Nil;
//	[rarArchive release];
	
	return comicPageImage;
	
}


@end
