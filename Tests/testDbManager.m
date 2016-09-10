//
//  testDbManager.m
//  Comic Phreak
//
//  Created by Mudit Vats on 3/4/16.
//  Copyright © 2016 HealthPro Solutions, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Comic.h"

@interface testDbManager : XCTestCase

@end

@implementation testDbManager

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
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"Bundle path: %@", [bundle bundlePath]);
    
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
