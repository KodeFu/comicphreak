//
//  ContentViewController.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 2/25/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

#import "ContentViewController.h"
#import "Debug.h"
#import "PathHelper.h"
#import "Comic.h"
#import "SizeHelper.h"

#pragma mark Globals

#pragma mark Inteface Methods
/****************************************************************************
 Interface Methods
 ****************************************************************************/
@interface ContentViewController ()

@end

#define PAGES_TO_CACHE_L4    14
#define PAGES_TO_CACHE_L3    10
#define PAGES_TO_CACHE_L2    6
#define PAGES_TO_CACHE_L1    4
#define PAGES_TO_CACHE_L0    0


@implementation ContentViewController
{
//    NSString *_fileName;
    Comic *comic;
    bool _comicOpenedOk;
    
    SizeHelper *_sizeHelper;
    
    // ScrollView Globals
    int g_oldScrollPage;
    int g_newScrollPage;
    
    NSLock			*g_cacheLock;
    int				g_cacheCurrentPage;
    bool            g_killThread;
    NSMutableArray	*g_cacheArray;
    UIImage			*g_emptyImageObject;
    int             g_maxPagesToCache;
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Custom initialization
        _comicOpenedOk = NO;
        
        // ScrollView Globals
        g_oldScrollPage = 0; // no change
        g_newScrollPage = 0; // no change
        
        g_cacheCurrentPage = 0; // no change
        g_killThread = NO;
        g_maxPagesToCache = PAGES_TO_CACHE_L4;
    }
    
    return self;
}


- (void)dealloc
{
    DLOG(@"dealloc");
    
	// Nil can happen if comic didn't load successfully
	if (comic != Nil)
	{
		// If we have valid comic, the cache gets
		// initialized, so deallocate only if the comic
		// is valid
		if (_comicOpenedOk)
		{
			if ([comic isValidComic])
			{
				// Release the cache
                g_emptyImageObject = Nil;
                g_cacheLock = Nil;
			}
		}
		comic = Nil;
	}
	
	// Remove any previous subviews
	for(UIView *subview in [[self _getZoomableView] subviews])
	{
		[subview removeFromSuperview];
	}
	[[self _getZoomableView] removeFromSuperview];

	_scrollView = Nil;
    _comicFileName = Nil;
}

#pragma mark View Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    DLOG(@"viewDidLoad");
    
}

-(void) viewWillAppear:(BOOL)animated
{
    DLOG(@"viewWillAppear");
    
    // FIXME: this will get called multiple times... need to not do this. Put some stuff
    // in viewDidLoad maybe and other stuff here. Or create a var for initialization.

    // New Comic - Do this in order! Read this again. Maintain order!
    
    // 1. Open the comic. If this doesn't work, we are done. If it works, we need
    // the the page numbers / metadata from the comic.
    if (![self _initializeComic]) return;
    
    // 2. Initialize the ScrollView. This setup up the scrollView and initializes
    // the sizeHelper. We use this for all content dimension, pages per screen etc.
    if (![self _initializeScrollView]) return;
    
	// 3. Initizalize Page Caching Thread. Start caching pages. This helps us since we
    // start loading pages in memory before we start populating new pages.
    if (![self _initializePageCachingThread]) return;
    
    // 4. Initialize the ScrollView with the first few pages
    if (![self _initializeScrollViewWithComicPages]) return;
    
    // 5. Initiailize Gesture Recognizers
    if (![self _initializeGestureRecognizers]) return;


    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController setHidesBarsOnTap:YES];
    
    _toolBar = self.navigationController.toolbar;
    
    CGRect newRect;
    newRect.origin.x = 0;
    newRect.origin.y = _scrollView.frame.size.height - _toolBar.frame.size.height;
    newRect.size.width = _scrollView.frame.size.width;
    newRect.size.height = _toolBar.frame.size.height;
    //[_toolBar setFrame:newRect];
    
    //self.navigationController.toolbar.frame = newRect;
    
    DLOG(@"toolbar %f %f %f %f", _toolBar.frame.origin.x, _toolBar.frame.origin.y, _toolBar.frame.size.width, _toolBar.frame.size.height);
    [self.view bringSubviewToFront:_toolBar];
}


- (void) viewWillDisappear:(BOOL)animated
{
    DLOG(@"viewWillDisappear");
    // Kill the thread -- HACK SHOULD HAPPEN WHEN BACK IS PRESSED!
    //g_killThread = YES;
    
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController setHidesBarsOnTap:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    DLOG(@"viewDidDisappear");
    // Kill the thread -- HACK SHOULD HAPPEN WHEN BACK IS PRESSED!
    g_killThread = YES;
}

- (void)didReceiveMemoryWarning
{
    DLOG(@"didReceiveMemoryWarning");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    switch (g_maxPagesToCache)
    {
        case PAGES_TO_CACHE_L4:
            g_maxPagesToCache = PAGES_TO_CACHE_L3;
            break;
        case PAGES_TO_CACHE_L3:
            g_maxPagesToCache = PAGES_TO_CACHE_L2;
            break;
        case PAGES_TO_CACHE_L2:
            g_maxPagesToCache = PAGES_TO_CACHE_L1;
            break;
        case PAGES_TO_CACHE_L1:
            g_maxPagesToCache = PAGES_TO_CACHE_L0;
        default:
            // Consider bailing out at this point. Close comic and exit view.
            g_maxPagesToCache = PAGES_TO_CACHE_L0;
            break;
    }
}

#pragma mark Rotation Methods

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [SizeHelper dumpScrollViewInfo:_scrollView];
    
    //debug
    //CGRect screenBound = [[UIScreen mainScreen] bounds];
    //CGSize screenSize = screenBound.size;
    //debug
    
    // Do custom rotation stuff now
    //DLOG(@"viewWillTransitionToSize to %fx%f", size.width, size.height);
    //DLOG(@"viewWillTransitionToSize current size %fx%f", screenSize.width, screenSize.height);
    
    // [SCROLL VIEW]
    // Resize the scrollView. Note: This is necessary, since it doesn't seem like
    // it's getting resized from the parent view.
    [_scrollView setAutoresizesSubviews:NO];
    [_scrollView setFrame:CGRectMake(0, 0, size.width, size.height)];
    
    // Set the scrollView content size and starting location
    _scrollView.contentSize = [_sizeHelper getContentSizeForDeviceSize:size];
    _scrollView.contentOffset = [_sizeHelper getOffsetforPage:g_oldScrollPage ForDeviceSize:size];

    [[self _getZoomableView] setAutoresizesSubviews:NO];
    [[self _getZoomableView] setFrame:CGRectMake(0, 0, [_sizeHelper getContentSizeForDeviceSize:size].width, size.height)];
    
    // Resize the page subviews
   	for(UIImageView *subview in [[self _getZoomableView] subviews])
    {
        [subview setAutoresizesSubviews:NO];
        [subview setFrame:[_sizeHelper getRectForPage:subview.tag ForDeviceSize:size]];
    }
    
    
    //DLOG(@"---> toolbar --     (%5.0f, %5.0f) %5.0fx%5.0f",
      //   _toolBar.frame.origin.x, _toolBar.frame.origin.y,
      //   _toolBar.frame.size.width, _toolBar.frame.size.height);
    
    
    //[[self.navigationController navigationBar] setHidden:YES];
    //self.navigationController.navigationBar
    DLOG(@"---> navigation --     (%5.0f, %5.0f) %5.0fx%5.0f",
         self.navigationController.navigationBar.frame.origin.x, self.navigationController.navigationBar.frame.origin.y,
         self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);

    
    CGRect newRect;
    newRect.origin.x = 0;
    newRect.origin.y = _scrollView.frame.size.height - _toolBar.frame.size.height;
    newRect.size.width = _scrollView.frame.size.width;
    newRect.size.height = _toolBar.frame.size.height;
    //[_toolBar setFrame:newRect];
    
    
    [SizeHelper dumpScrollViewInfo:_scrollView];
    
}
/*
- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize
{
    DLOG(@"parentSize width=%f, height=%f", parentSize.width, parentSize.height);
    
    CGSize size;
    
    size.width = 0.0f;
    size.height = 0.0f;
    
    
    return size;
}*/

#pragma mark Zooming
- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    //DLOG(@"viewForZoomingInScrollView");
    
    //CHECK IF WE HAVE COMIC OPEN!
    
    // Specify which object you should zoom - Zoom the entire scrollView
    return [self _getZoomableView];
}

- (void) scrollViewDidZoom:(UIScrollView *)scrollView
{
    //DLOG(@"scrollViewDidZoom");
}

- (void) scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    //DLOG(@"scrollViewWillBeginZooming");
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    //DLOG(@"scrollViewDidEndZooming");
    
    // The setPaging here exists so that when you zoom and move that zoom rect,
    // the scrollView doesn't automatically try to page to an edge. This has the
    // effect of "sticking" to an edge when you don't want that to happen.
    
    if (scale != 1.0)
    {
        [_scrollView setPagingEnabled:NO];
    }
    else
    {
        [_scrollView setPagingEnabled:YES];
    }
}

#pragma mark Initializers

- (BOOL) _initializeComic
{
    NSString *filePath = [PathHelper getDocumentsPathWithFilename:_comicFileName];
    comic = [[Comic alloc] initWithFileName:filePath];
    
    if (comic == Nil)
	{
        DLOG(@"couldn't allocate comic");
        return false;
    }
    
    if (![comic openComic])
    {
        DLOG(@"couldn't open comic ... grrr");
        return false;
    }
    
    // We opened the comic ok! Yay!
	_comicOpenedOk = YES;
    
    // Set title of comic
    //[[self navigationItem] setTitle:_comicFileName];    
    
    return true;
}

- (BOOL) _initializeScrollView
{
    // Initialize the SizeHelper. We need this to calculate dimensions for all views.
#pragma warn Need to set pages per screena and scale factor from prefs or resume!
    _sizeHelper = [[SizeHelper alloc] initWithNumberOfPages:[comic comicTotalPages] AndMangaMode:false AndScaleFactor:1.0];
    if (_sizeHelper == Nil)
    {
        DLOG(@"couldn't allocate sizeHelper");
        return false;
    }
    
#pragma warn Hack to enable Manga
//    [_sizeHelper setIsManga:true];
//    [_sizeHelper doSomeCrap]; // pad a page because is Manga... clean up later....
    //
    
    // [SCROLL VIEW]
    // Remove an previous subview
    if ([self _getZoomableView])
    {
        // Remove any previous subviews
        for(UIView *subview in [[self _getZoomableView] subviews])
        {
            [subview removeFromSuperview];
        }
        
        [[self _getZoomableView] removeFromSuperview];
    }
    
    // Resize the scrollView. Note: This is necessary, since it doesn't seem like
    // it's getting resized from the parent view.
    [_scrollView setFrame:[SizeHelper getDeviceRect]];
    [_scrollView setContentSize:[_sizeHelper getContentSize]];
    [_scrollView setContentOffset:[_sizeHelper getOffsetforPage:0]];
    
    [_scrollView setAutoresizesSubviews:NO];
    
    // Preferences
    [_scrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    

    // [ZOOMABLE VIEW]
	// Add the one and only view. This view is the container for all pages subviews.
    // We are just adding the view here. We do not set dimensions at this point.
	UIView *zoomableView = [[UIView alloc] init];
    if (zoomableView == Nil)
    {
        DLOG(@"couldn't allocate zoomableView");
        return false;
    }

    // Set the one and only views size. Resize the zoomableView so that
    // it's the size of the content. zoomableView needs to stay the same size as
    // the content since it is the container view. Second in the hierarchy.
	[zoomableView setTag:-99]; // Set tag to -99 so it doesn't get deleted
	[zoomableView setFrame:[_sizeHelper getContentRect]];
	[zoomableView setAutoresizesSubviews:NO];
    
    // Add the zoomableView to the scrollView. We now have _scrollView->zoomableView.
	[_scrollView addSubview:zoomableView];
    zoomableView =  Nil;
    
    return true;
}

- (BOOL) _initializePageCachingThread
{
    // Start the thread
	g_killThread = NO;
	g_cacheLock = [[NSLock alloc] init];
    if (g_cacheLock == Nil)
    {
        DLOG(@"couldn't allocate cacheLock");
        return false;
    }
	
	// Create the cacheArray with a capacity of the total pages
	g_cacheArray = [[NSMutableArray alloc] initWithCapacity:[comic comicTotalPages]];
    if (g_cacheArray == Nil)
    {
        DLOG(@"couldn't allocate cacheArray");
        return false;
    }
	
	// Populate with empty objects
	g_emptyImageObject = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"error_bad_page" ofType:@"png"]];
    if (g_emptyImageObject == Nil)
    {
        DLOG(@"couldn't allocate emptyImageObject");
        return false;
    }
    
	for (int i=0; i<[comic comicTotalPages]; i++)
    {
		[g_cacheArray addObject:g_emptyImageObject];
	}
    
    // Start the page cache thread
	[NSThread detachNewThreadSelector:@selector(_cacheThread:) toTarget:self withObject:self];
    
    return true;
}

- (BOOL) _initializeScrollViewWithComicPages
{
    int startPage = 0;
    int endPage = 4;
    
    if (g_oldScrollPage)
    {
        startPage = g_oldScrollPage;
        endPage = g_oldScrollPage + endPage;
    }
    
    startPage = MAX(0, startPage);
    endPage =   MAX(0, endPage);
    startPage = MIN([comic comicTotalPages], startPage);
    endPage =   MIN([comic comicTotalPages], endPage);
    
    for (int i=startPage; i<endPage; i++)
    {
        [self _insertPage:i];
    }
    
    // DEBUG
    //DLOG(@"+++ startPage %d, endPage %d", startPage, endPage);
    
    _scrollView.contentOffset = [_sizeHelper getOffsetforPage:startPage];
    g_oldScrollPage = startPage;
    g_newScrollPage = startPage;
    
    return true;
}

- (BOOL) _initializeGestureRecognizers
{
    /////////////////////
	// Add the gesture recognizers
	/////////////////////
	/*
	// Single Tap
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
											 initWithTarget:self
											 action:@selector(handleTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self.scrollView addGestureRecognizer:tapRecognizer];*/
    
	// Double Tap
	UITapGestureRecognizer *tapRecognizerDouble = [[UITapGestureRecognizer alloc]
												   initWithTarget:self
												   action:@selector(handleDoubleTap:)];
    tapRecognizerDouble.numberOfTapsRequired = 2;
    
    // Always try double tap first, then fail to single tap (which is in the navigation controller)
    [self.navigationController.barHideOnTapGestureRecognizer requireGestureRecognizerToFail:tapRecognizerDouble];
    
    [self.scrollView addGestureRecognizer:tapRecognizerDouble];
	
//	tapRecognizer = Nil;
	tapRecognizerDouble = Nil;
    
    return true;

}

#pragma mark Gesture Recognizer Handlers
- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
	/*
     CGPoint tapPoint = [recognizer locationInView:_scrollView];
	CGPoint tapPointInView = [_scrollView convertPoint:tapPoint toView:self.view];
	float viewWidth = [_scrollView frame].size.width;
	float pageMargin;
	
	// Choose the right page margin
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		pageMargin = PAGE_ADVANCE_WIDTH_IPHONE;
	}
	else
	{
		pageMargin = PAGE_ADVANCE_WIDTH_IPAD;
	}
	
	if (tapPointInView.x<pageMargin)
	{
		// Previous Page
		g_pageAdvance = true;
		g_newScrollPage = MAX(g_newScrollPage-1, 0);
		[self scrollViewDidEndDecelerating:_scrollView];
	}
	else if (tapPointInView.x>(viewWidth-pageMargin))
	{
		// Page advance
		g_pageAdvance = true;
		g_newScrollPage = MIN(g_newScrollPage+1, [comic comicTotalPages]-1);
		[self scrollViewDidEndDecelerating:_scrollView];
	}
	else
	{
		[self animateUserInterface];
	}
     */
    
    
    //[[self.navigationController navigationBar] setHidden:self.navigationController.isToolbarHidden? NO:YES];
    
    //[_scrollView bringSubviewToFront:[[self.navigationController navigationController] view]];
    //[[self.navigationController navigationBar] setHidden:YES];
//    [self.navigationController setNavigationBarHidden:self.navigationController.navigationBar.isHidden?NO:YES animated:YES];;
//    [self.navigationController setToolbarHidden:self.navigationController.toolbar.isHidden?NO:YES animated:YES];
    //[[self.navigationController navigationBar] setHidden:self.navigationController.navigationBar.isHidden?NO:YES];
    //[_scrollView.superview bringSubviewToFront:self.navigationController.navigationBar];
    //[_toolBar setHidden:_toolBar.isHidden?NO:YES];
    
    
    
    DLOG(@"handleTap");
    
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{

    DLOG(@"Handle zoomRectForScale");
    
    CGRect zoomRect;
	
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = [_scrollView frame].size.height / scale;
    zoomRect.size.width  = [_scrollView frame].size.width  / scale;
    
#warning Not sure if we need the other center here. It's commented out, but look into it.
    //DLOG(@"scrollView scale=%f, width=%f, height=%f", scale, zoomRect.size.width, zoomRect.size.height);
    //DLOG(@"passed in center.x=%f, center.y=%f", center.x, center.y);
    
    //center = [_scrollView convertPoint:center
    //                          fromView:[[[self scrollView] subviews] objectAtIndex:0] ];

    //DLOG(@"zoomView center.x=%f, center.y=%f", center.x, center.y);
	
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
	
    return zoomRect;
}

- (void) handleDoubleTap:(UITapGestureRecognizer*)recognizer
{
    /*
     Do we need this????
	if (!g_openedOk)
	{
		return;
	}*/
	
	float newScale = [self.scrollView zoomScale] * 2.0;
	
    if ([self.scrollView zoomScale] > [self.scrollView minimumZoomScale])
    {
		// Unzoom view
        [self.scrollView setZoomScale:[self.scrollView minimumZoomScale] animated:YES];
    }
    else
    {
		// Zoom view
        CGRect zoomRect = [self zoomRectForScale:newScale
									  withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
    
    DLOG(@"handleDoubleTap");
}


#pragma mark InsertPage...
- (UIView *) _getZoomableView
{
    UIView *zoomableView = Nil;
    
    if ([[_scrollView subviews] count])
    {
        zoomableView = ((UIView *)[[_scrollView subviews] objectAtIndex:0]);
    }
    
    return zoomableView;
}

- (BOOL) _insertPage: (int) page
{

    DLOG(@"_insertPage");
    
    UIImage *comicImage = Nil;
    UIImageView *imageView;
    BOOL err = NO;

    if ((page<0) || (page>=[comic comicTotalPages]))
	{
        DLOG(@"page out of bounds");
        goto DONE;
    }

    // Get the comic image
	[g_cacheLock lock];
	
	comicImage = [g_cacheArray objectAtIndex:page];
	
	if ([comicImage isEqual:g_emptyImageObject])
	{
		[g_cacheLock unlock];
		DLOG(@"........ got lock, but slow load %d", page);
		comicImage = [comic getImageAtIndex:page];
		imageView = [[UIImageView alloc] initWithImage:comicImage];
        comicImage = Nil;
	}
	else
	{
		//DLOG(@"........ got lock, fast load %d", page);
		if (comicImage == Nil)
		{
			DLOG(@"insert image failed");
			[g_cacheLock unlock];
			goto DONE;
		}
		
		imageView = [[UIImageView alloc] initWithImage:comicImage];
		[g_cacheLock unlock];
	}

    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setFrame:[_sizeHelper getRectForPage:page]];
    //DLOG(@"imageView page: %d setFrame (%f, %f, %f, %f)", page, imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height );
	[imageView setTag:page];
    
    [imageView setAutoresizesSubviews:NO];
	
	// Add the subview
    [[self _getZoomableView] addSubview:imageView];
	
	// We alloced, so release it
    imageView = Nil;
	
    // Success
    err = YES;
	
DONE:
    return err;
}

-(void) scrollViewWillBeginDecelerating:(UIScrollView *)scrollViewParemeter
{
	// Stop scrolling, so we only advance one page
	[scrollViewParemeter setScrollEnabled:NO];
}


- (void) scrollViewDidEndDecelerating:(UIScrollView *) scrollView
{
    //
	//DLOG(@"page slider value %f", [pageSlider value]);
    
    // Get the new pages using the scrollView offset. We skip getting the...
    CGFloat pageWidth = [SizeHelper getDeviceWidth];
    g_newScrollPage = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    g_newScrollPage = [_sizeHelper getTranslatedPage:g_newScrollPage];

    // Note: The caching thread works on g_newScrollPage, so when we get a new page, the thread
    // will attempt to cache pages around that new scroll page for easy loading.
    
    // If page changed, scroll the page
	if ((g_newScrollPage != g_oldScrollPage))
	{
		//DLOG(@"oldpage %d, newpage %d", g_oldScrollPage, g_newScrollPage);
		
        //FIXME: Maybe check if g_newScrollPage<0. Check to see if we can ever get this condition.
        if (g_newScrollPage>=[_sizeHelper pagesTotal])
        {
            DLOG(@"scrolling to page (%d) greater than total pages (%d)", g_newScrollPage, [comic comicTotalPages]);
            goto DONE;
        }
        
        // Clamp cacheStart and cacheEnd pages so that
        // they fall within the range 0...Max Comic Pages
        int subviewStart = g_newScrollPage - 5;
        int subviewEnd = g_newScrollPage + 5;
        
        subviewStart = MAX(0, subviewStart);
        subviewEnd =   MAX(0, subviewEnd);
        subviewStart = MIN([_sizeHelper pagesTotal], subviewStart);
        subviewEnd =   MIN([_sizeHelper pagesTotal], subviewEnd);
        
        //DLOG(@"--- subviewStart %d subivewEnd %d -- %d", subviewStart, subviewEnd, g_newScrollPage);
        
        // Load the views we want
        int i;
        for (i=subviewStart; i<subviewEnd; i++)
        {
            if ([[self _getZoomableView] viewWithTag:(i)]==Nil)
            {
                // Only insert if the view for that page is not added
                [self _insertPage:i];
            }
        }
        
        // Remove the views we don't want
        for (i=0; i<subviewStart; i++)
        {
            UIView *removeMe = [[self _getZoomableView] viewWithTag:(i)];
            [removeMe removeFromSuperview];
            removeMe =  Nil;
        }
        
        for (i=subviewEnd; i<[comic comicTotalPages]; i++)
        {
            UIView *removeMe = [[self _getZoomableView] viewWithTag:(i)];
            [removeMe removeFromSuperview];
            removeMe =  Nil;
        }
        
		// Update the page number
		g_oldScrollPage = g_newScrollPage;
        
	}

DONE:
	// Start scrolling again
	[scrollView setScrollEnabled:YES];
}


#pragma mark Image Caching Thread
- (void) _cacheThread : (int) index
{
	int i = 0;
	int cachedNewPage;
	int cacheStart;
	int cacheEnd;
	UIImage *tmpObject;
	   
    @autoreleasepool
    {
        while (!g_killThread)
        {
            // Copy the newPage, since the newPage may change on a scroll
            cachedNewPage = g_newScrollPage;
            
            if (cachedNewPage==g_cacheCurrentPage)
            {
                // Page did not change, nothing to cache.
                // Take a short nap.
                usleep(50);
                continue;
            }
            else
            {
                // Page changed, try to cache new pages.
                // If no lock, main thread is doing something, try
                // again later.
                if (![g_cacheLock tryLock])
                {
                    usleep(200);
                    continue;
                }
            }
            
            // Clamp cacheStart and cacheEnd pages so that
            // they fall within the range 0...Max Comic Pages
            cacheStart = cachedNewPage - g_maxPagesToCache / 2;
            cacheEnd = cachedNewPage + g_maxPagesToCache / 2;

            cacheStart = MAX(0, cacheStart);
            cacheEnd =   MAX(0, cacheEnd);
            cacheStart = MIN([comic comicTotalPages], cacheStart);
            cacheEnd =   MIN([comic comicTotalPages], cacheEnd);
            
            // Zero all cached items before the cache range
            for (i=0; i<cacheStart; i++)
            {
                tmpObject = [g_cacheArray objectAtIndex:i];
                
                if (![tmpObject isEqual:g_emptyImageObject])
                {
                    // Remove the cached object
                    [g_cacheArray removeObjectAtIndex:i];
                    
                    // Note, we don't release comic pages, becuase we release
                    // right after we add the object to the array
                    
                    // Insert empty object
                    [g_cacheArray insertObject:g_emptyImageObject atIndex:i];
                }
            }
            
            // Zero all cached items after the cache range
            for (i=cacheEnd; i<[comic comicTotalPages]; i++)
            {
                tmpObject = [g_cacheArray objectAtIndex:i];
                if (![tmpObject isEqual:g_emptyImageObject])
                {
                    // Remove the cached object
                    [g_cacheArray removeObjectAtIndex:i];
                    
                    // Note, we don't release comic pages, becuase we release
                    // right after we add the object to the array
                    
                    // Insert empty object
                    [g_cacheArray insertObject:g_emptyImageObject atIndex:i];
                }
            }
            
            //DLOG(@"cacheThread: cacheStart %d cacheEnd %d array count %d", cacheStart, cacheEnd, [g_cacheArray count]);
            
            @autoreleasepool
            {
                // Cache pages within range of the current page
                for (i=cacheStart; i<cacheEnd; i++)
                {
                    tmpObject = [g_cacheArray objectAtIndex:i];
                    if ([tmpObject isEqual:g_emptyImageObject])
                    {
                        // Remove the previous object
                        [g_cacheArray removeObjectAtIndex:i];
                        
                        // Release the previous object (empty or otherwise)
                        //[tmpObject release];
                        // Don't do this! We release the UIImage right away since we
                        // allocated it. All other objects are just added and removed.
                        // Those we didn't allocate in this loop.
                        
                        // Add the comic page
                        UIImage *tmpImage = [comic getImageAtIndex:i];
                        [g_cacheArray insertObject:tmpImage atIndex:i];
                        
                        // Don't forget to release the comic page
                        tmpImage = Nil;
                    }
                }
            }
            
            g_cacheCurrentPage = cachedNewPage;

            
            [g_cacheLock unlock];
            
        }
        
KILLME:
        [g_cacheArray removeAllObjects];
        g_cacheArray = Nil;
        
    } // @autoreleasepool
}


- (IBAction)OnBarButtonItemPressed:(id)sender
{
    
    DLOG(@"- SuperView Frame     (%5.0f, %5.0f) %5.0fx%5.0f",
         _scrollView.superview.frame.origin.x, _scrollView.superview.frame.origin.y,
         _scrollView.superview.frame.size.width, _scrollView.superview.frame.size.height);

    [SizeHelper dumpScrollViewInfo:_scrollView];
    
    //debug
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    //debug
    
    // Do custom rotation stuff now
    //DLOG(@"viewWillTransitionToSize to %fx%f", size.width, size.height);
    //DLOG(@"viewWillTransitionToSize current size %fx%f", screenSize.width, screenSize.height);
    
    // [SCROLL VIEW]
    // Resize the scrollView. Note: This is necessary, since it doesn't seem like
    // it's getting resized from the parent view.
    [_scrollView setAutoresizesSubviews:NO];
    [_scrollView setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    
    DLOG(@"- SuperView Frame     (%5.0f, %5.0f) %5.0fx%5.0f",
         _scrollView.superview.frame.origin.x, _scrollView.superview.frame.origin.y,
         _scrollView.superview.frame.size.width, _scrollView.superview.frame.size.height);
    
    [SizeHelper dumpScrollViewInfo:_scrollView];
    
}
@end
