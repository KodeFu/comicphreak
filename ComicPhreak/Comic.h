//
//  Comic.h
//  SplitDemo
//
//  Created by Mudit Vats on 3/22/12.
//  Copyright 2012 HealthPro Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZipFile.h"
#import "Unrar4iOS.h"


@interface Comic : NSObject


@property (copy) NSString *comicFileName;
@property (assign) int comicCurrentPage;
@property (assign) int comicTotalPages;
@property (retain) NSMutableArray *directoryOfPages;
@property (assign, nonatomic) BOOL isValidComic;

// Common Methods
- (id) initWithFileName: (NSString *) name;
- (BOOL) openComic;
- (UIImage *) getImageAtIndex: (int) index;

@end
