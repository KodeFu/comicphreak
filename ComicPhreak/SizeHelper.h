//
//  SizeHelper.h
//  Comic Phreak DB
//
//  Created by Mudit Vats on 5/13/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SizeHelper : NSObject

@property float scaleFactor;
@property int pagesTotal;
@property bool isManga;

// Class Methods

// Debug Methods
+ (void) dumpScrollViewInfo:(UIScrollView *) scrollView;

// Device Size Methods
+ (float) getDeviceWidth;
+ (float) getDeviceHeight;
+ (CGRect) getDeviceRect;


// Interface Methods

// Note, there are two kinds of interface methods: Ones that deal with device
// size and ones that deal with a size passed in. The ones that deal with device
// size, use the current devie's size. The other ones allow a size to be passed
// in, which can be any new device size; typically, this is a new device size
// use for rotation.

// Initialization
- (id) init;
- (id) initWithNumberOfPages: (int) pages;
- (id) initWithNumberOfPages: (int) pages AndMangaMode: (bool) isManga AndScaleFactor: (float) scaleFactor;

// Content Methods
- (CGRect) getContentRect;
- (CGSize) getContentSize;
- (CGRect) getContentRectForDeviceSize: (CGSize) size;
- (CGSize) getContentSizeForDeviceSize: (CGSize) size;

// Page Methods
- (CGRect)  getRectForPage: (int) page;
- (CGPoint) getOffsetforPage: (int) page;
- (CGRect)  getRectForPage: (int) page ForDeviceSize: (CGSize) size;
- (CGPoint) getOffsetforPage: (int) page ForDeviceSize: (CGSize) size;

// This is used by ContentView and by SizeHelper. ContentView is using it so that it can get the page number
// from a give offset. That functionality needs to be moved to SizeHelper. Then only SizeHelper will do any
// page translation.
// But, for a page slider, the page numbers are 0...50 for US and 50..0 for Manga. So, the slider page number
// should use the viewTag only.
- (int) getTranslatedPage: (int) page;

@end
