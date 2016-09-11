//
//  SizeHelper.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 5/13/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

/*
 ScrollView Design
 
   V---- scrollView (640x1920; outer view)
 =================================================  <-- zoomableView
 [ +----------+----------+----------+----------+ ]      640x(480*4pages)
 [ |          |          |          |          | ]      640x1920
 [ |          |          |          |          | ]
 [ |          |          |          |          | ]
 [ | SubView0 | SubView1 | SubView2 | SubView3 | ]
 [ | 640x480  | 640x480  | 640x480  | 640x480  | ]
 [ |          |          |          |          | ]
 [ |          |          |          |          | ]
 [ +----------+----------+----------+----------+ ]
 =================================================
 
 ScrollView contains one UIView called zoomableView. The size of the zoomableView
 is set to the size of the number of comic book pages - to contain them all.
 
 Comic pages area added as subViews of the zoomableView.
 
 UIScrollView scrollView
   |--> UIView zoomableView
     |--> UIView subView 0
     |--> UIView subView 1
     |--> UIView subView 2
     |--> UIView subView 3
 
 
 scrollView - # of pages * pageWidth
 zoomableView - # of pages * pageWidth
 
* scrollView and zoomableView are the same size. We call this size the
  ContentSize.
 
 On Zooming:
 Zooming works by scaling the zoomableView by a zoom factor and centering on the
 point that was tapped.
 
 On Rotation:
 Rotation works by resizing the zoomableView's frame and content sizes based on the
 new orientation of the pages. Also,
 
 Also, note, in our implementaiton, there is one more view before the scrollView and
 that is the view of the application.
 
 UIView view
     |--> UIScrollView scrollView
         |--> UIView zoomableView
             |--> UImageView page(s)
 */

/*
 Need a class where we can abstract size calculations for a given scrollview.
 
 Given:
    ScrollView
    Number or Comic Pages
 
 Retrieved
    Zoom Factor
 
 Calculated
    Device Width and Height
 
 Instantiated
    At the creation of a new ScrollView
 
 Returns
    The SizeRect structures for Zooming, Rotation and Scrolling.
 */

/*
 Multipage Support
 - Regardless of orientation, handle multiple pages per screen.
 - Two pages side-by-side configuration. Only really useful for Landscape.
 - Four pages per screen? Not sure if this is possible or desirable. Probably
   only useful for Portrait.
 
 Need some new functions
 - getPagesPerScreen
 
 Need a new property
 - pagesPerScreen
 
 
*/

#import "SizeHelper.h"
#import "Debug.h"

@implementation SizeHelper


#pragma mark Initializers
- (id)init
{
    self = [super init];
	
    if (self)
    {
		// Do some initializization...
        [self initializeObject];
	}
	
    return self;
}

- (id) initWithNumberOfPages: (int) pages
{
	self = [super init];
	
    if (self)
    {
        // Initialize with default
        [self initializeObject];
        
        // Update values
        _pagesTotal = pages;
	}
	
    return self;
}

- (id) initWithNumberOfPages: (int) pages AndMangaMode: (bool) isManga AndScaleFactor: (float) scaleFactor
{
	self = [super init];
	
    if (self)
    {
        // Initialize with default
        [self initializeObject];
        
        // Update values
        _pagesTotal = pages;
        _scaleFactor = scaleFactor;
        _isManga = isManga;
	}
	
    return self;
}

- (void) initializeObject
{
    _pagesTotal = 0;
    _scaleFactor = 1.0;
    _isManga = false;
}


#pragma mark Debug Helpers
+ (void) dumpScrollViewInfo:(UIScrollView *) scrollView
{
	DLOG(@"- ScrollView Content   (%5.0f, %5.0f) %5.0fx%5.0f %.2fx",
         scrollView.contentOffset.x, scrollView.contentOffset.y,
         scrollView.contentSize.width, scrollView.contentSize.height,
         scrollView.zoomScale);
    
	DLOG(@"- ScrollView Frame     (%5.0f, %5.0f) %5.0fx%5.0f",
         scrollView.frame.origin.x, scrollView.frame.origin.y,
         scrollView.frame.size.width, scrollView.frame.size.height);
	
    UIView *tmpView = [[scrollView subviews] objectAtIndex:0];
    DLOG(@"- ZoomableView Frame   (%5.0f, %5.0f) %5.0fx%5.0f",
         tmpView.frame.origin.x, tmpView.frame.origin.y,
         tmpView.frame.size.width, tmpView.frame.size.height);
    
    int i=0;
	for(UIImageView *subview in [[[scrollView subviews] objectAtIndex:0] subviews])
	{
        DLOG(@"- ZoomableView S%dT%d  (%5.0f, %5.0f) %5.0fx%5.0f", i, ((int) subview.tag),
             subview.frame.origin.x, subview.frame.origin.y,
             subview.frame.size.width, subview.frame.size.height);
        i++;
	}
}

#pragma mark *** Class Methods ***
#pragma mark Device Dimenion Methods

// This method gets the current device width
+ (float) getDeviceWidth
{
	CGRect screenBound = [[UIScreen mainScreen] bounds];
	CGSize screenSize = screenBound.size;
    
    //DLOG(@"--> getDeviceWidth: %f", screenSize.width);
    
    return screenSize.width;
}

// This method gets the current device height
+ (float) getDeviceHeight
{
	CGRect screenBound = [[UIScreen mainScreen] bounds];
	CGSize screenSize = screenBound.size;
	
    //DLOG(@"--> getDeviceHeight: %f", screenSize.height);
    
    return screenSize.height;
}

+ (CGRect) getDeviceRect
{
    CGRect rect = CGRectMake(
            0,
            0,
            [SizeHelper getDeviceWidth],
            [SizeHelper getDeviceHeight]);
    
    return rect;
}

#pragma mark *** Instance Methods ***


#pragma mark Content Size Methods

// This method gets the content's width
- (float) _getContentWidth
{
    return _pagesTotal * [SizeHelper getDeviceWidth] * _scaleFactor;
}

// This method gets the content's height
- (float) _getContentHeight
{
    return [SizeHelper getDeviceHeight] * _scaleFactor;
}

// This method gets the content's width for an interface orientation
- (float) _getContentWidthForInterfaceOrientation: (CGSize) size
{
    //DLOG(@">> pages: %d, width: %f, scale: %f", _pagesTotal, size.width, _scaleFactor);
    return _pagesTotal * size.width * _scaleFactor;
}

// This method gets the content's height for an interface orientation
- (float) _getContentHeightForInterfaceOrientation: (CGSize) size
{
    return size.height * _scaleFactor;
}

#pragma mark Page Offset Methods

// This method gets the offset, starting location of the page, of the specified page
- (float) _getPageOffsetInContentWithPage: (int) page
{
    float pageOffset;
    int translatedPage = [self getTranslatedPage:page];
    
    //DLOG(@"--> translatedPage %d", translatedPage);
    
    pageOffset = translatedPage * [SizeHelper getDeviceWidth];
    
    //DLOG(@"pageOffset %f", pageOffset);
    
    return pageOffset;
}

// This method gets the offset, starting location of the page, of the specified page for an interface orientation
- (float) _getPageOffsetInContentWithPage: (int) page ForSize: (CGSize) size
{
    float pageOffset;
    int translatedPage = [self getTranslatedPage:page];
    
    pageOffset = translatedPage * size.width;
    
    return pageOffset;
}

#pragma mark Rect Methods

// This method returns the rect which defines the frame of the ScrollView. This
// is the monster size. Same as getScrollViewSize, but as a rect.
- (CGRect) getContentRect
{
    CGRect rect = CGRectMake(
                0,
                0,
                [self _getContentWidth],
                [self _getContentHeight]
                );
    
    return rect;
}

// This method returns the size of the ScrollView. This is the monster size with all
// pages.
- (CGSize) getContentSize
{
    CGSize size = CGSizeMake(
                [self _getContentWidth],
                [self _getContentHeight]
                );
    
    return size;
}

// This method returns the rect for the content for an inteface orientation. Note, the offset
// is set to the upper left hand corner.
- (CGRect) getContentRectForDeviceSize:(CGSize)size
{
    CGRect rect = CGRectMake(
                             0,
                             0,
                             [self _getContentWidthForInterfaceOrientation:size],
                             [self _getContentHeightForInterfaceOrientation:size]);
    
    return rect;
}

// This method returns the size for the ScrollView based on the inteface orientation.
- (CGSize) getContentSizeForDeviceSize:(CGSize)size
{
    CGSize retSize = CGSizeMake(
                             [self _getContentWidthForInterfaceOrientation:size],
                             [self _getContentHeightForInterfaceOrientation:size]);
    
    return retSize;
}

#pragma mark Page Location Methods

// This method returns a rect that defines a page at an X coordinate someplace in
// the ScrollView's rectangle. So, page 3, would be three page width's from the left.
// Also note that the width and height are for the device, not the ScrollView's.
- (CGRect) getRectForPage: (int) page
{
    CGRect rect;
    
    rect = CGRectMake(
                [self _getPageOffsetInContentWithPage:page],
                0,
                [SizeHelper getDeviceWidth],
                [SizeHelper getDeviceHeight]
                );

    return rect;
}

#pragma warn Need to comprehend zoom location point also!

// This method returns the offset in the ScrollView for a given page. Note, that
// Y coordinate is always zero.
- (CGPoint) getOffsetforPage: (int) page
{
    CGPoint contentOffset = [self getRectForPage:page].origin;

    return contentOffset;
}

// This method returns a rect that defines a page at an X coordinate someplace in
// the ScrollView's rectangle. So, page 3, would be three page width's from the left.
// Also note that the width and height are for the device, not the ScrollView's.
- (CGRect) getRectForPage: (int) page ForDeviceSize: (CGSize) size
{
    CGRect rect;
    
    rect = CGRectMake(
                      [self _getPageOffsetInContentWithPage:page ForSize:size],
                      0,
                      size.width,
                      size.height
                      );
    
    return rect;
}
// This method returns the offset in the ScrollView for a given page. Note, that
// Y coordinate is always zero.
- (CGPoint) getOffsetforPage: (int) page ForDeviceSize: (CGSize) size
{
    CGPoint contentOffset = [self getRectForPage:page ForDeviceSize:size].origin;
    
    return contentOffset;
}

#pragma mark Manga Page Methods

- (int) getTranslatedPage: (int) page
{
    if (_isManga)
    {
        DLOG(@"IS MANGA!");
        return abs((_pagesTotal-1) - page);
    }
    else
    {
        return page;
    }
}

@end
