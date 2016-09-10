//
//  testComic.m
//  Comic Phreak
//
//  Created by Mudit Vats on 3/4/16.
//  Copyright © 2016 HealthPro Solutions, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PathHelper.h"
#import "comic.h"
#import "Debug.h"

/*
 @property (copy) NSString *comicFileName;
 @property (assign) int comicCurrentPage;
 @property (assign) int comicTotalPages;
 @property (retain) NSMutableArray *directoryOfPages;
 @property (assign, nonatomic) BOOL isValidComic;
 
 // Common Methods
 - (id) initWithFileName: (NSString *) name;
 - (BOOL) openComic;
 - (UIImage *) getImageAtIndex: (int) index;
 */

@interface testComic : XCTestCase

@end

@implementation testComic

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    DLOG(@"%s %d\n", __PRETTY_FUNCTION__, __LINE__);
    
    /*
    NSString *filePath = [PathHelper getDocumentsPathWithFilename:@"Alias 001.cbr"];
    DLOG(@"%@\n", filePath);
    Comic *comic = [[Comic alloc] initWithFileName:filePath];
    
    [comic openComic];
    */
    
    // Get comics from a Comics directory. That is more real-world. If
    // I get it from the test bundle, it picks up other files as well which
    // will not work. Unless you filter based on type.
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"Bundle path: %@", [bundle bundlePath]);
    [PathHelper getDirectoryListingAtPath:[bundle bundlePath]];
    
    NSString *filePath = [bundle pathForResource:@"delete" ofType:@"cbr"];
    NSLog(@"Path for file: %@", [bundle pathForResource:@"delete" ofType:@"cbr"]);
    
    Comic *comic = [[Comic alloc] initWithFileName:filePath];
    
    BOOL value = [comic openComic];
    
    XCTAssert(value);
}

- (void)DISABLE_testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
