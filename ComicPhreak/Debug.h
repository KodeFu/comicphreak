//
//  Debug.h
//  Comic Phreak
//
//  Created by Mudit Vats on 5/2/12.
//  Copyright (c) 2012 HealthPro Solutions, LLC. All rights reserved.
//

#ifndef Comic_Phreak_Debug_h
#define Comic_Phreak_Debug_h

#define APPLICATION_VERSION			4.0

// iAD Supported Version
// -- Uncomment ENABLE_ADS define
// -- set Bundle Identifier to com.comicphreak.ComicPhreakFree
// -- Change Icons to the Free Version (change the names in "Comic Phreak-Info.plist" file
// -- Connect iAd Banner control to IBOutlet in ScrollView.h (iPhone and iPad xib files)
// -- Connect iAd Banner's delegate connection to File Owner (iPhone and iPad xib files)
// -- Add iAd.Framework to Comic Phreak->Target Comic Phreak->Build Phases->Link Binary With Libraries. Right click on Comic Phreak project first.
#define ENABLE_ADS					1 // Comment this out for non-Ad version

// DLog is almost a drop-in replacement for NSLog
// DLog();
// DLog(@"here");
// DLog(@"value: %d", x);
// Unfortunately this doesn't work DLog(aStringVariable); you have to do this instead DLog(@"%@", aStringVariable);
#ifdef DEBUG
//#define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define DLOG NSLog
#define DLOG(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
//#define DLOG(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define DLOG(...)
#endif

// ALog always displays output regardless of the DEBUG setting
#define ALOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#define REFCOUNT(object) DLOG("reference count %d", object.retainCount);


/*
 *  System Versioning Preprocessor Macros
 */ 

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/* A word about proportions
 * For CP, we are using a .65 ratio for width to height. Exampeles --
 *   650 width x 1000 height = .65 ratio.
 *   Use this ratio for all thumbnails.
 */


#define DEBUG_PRINT_SIMDIR NSLog(@"app dir: %@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);

/*
 * UIColor Conversion
 * http://foobarpig.com/iphone/uicolor-cheatsheet-color-list-conversion-from-and-to-rgb-values.html
 */
#define UIColorFromRGB(rgbValue) [UIColor \
	colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
	green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
	blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//usage
//UIColor color = UIColorFromRGB(0xF7F7F7);

/*
 Some code to output fonts supported --
 http://iosdevelopertips.com/design/available-fonts-on-iphone.html
 
 Site for font family support based on iOS version --
 
 
 NSString *family, *font;
 for (family in [UIFont familyNames])
 {
 DLOG(@"\nFamily: %@", family);
 
 for (font in [UIFont fontNamesForFamilyName:family])
 DLOG(@"\tFont: %@\n", font);
 }
 */

#endif
