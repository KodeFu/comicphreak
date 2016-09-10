//
//  NavigationViewController.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 9/8/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import "NavigationViewController.h"
#import "Debug.h"

@interface NavigationViewController ()

@end

@implementation NavigationViewController

// Doesn't seem to be called. Leaving here for now.... SO says delete.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    /*
    // Register for notification events
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveNotification:)
                                                 name:@"START_SYNC"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveNotification:)
                                                 name:@"STOP_SYNC"
                                               object:nil];
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}
/*
- (void) receiveNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"START_SYNC"])
	{
        //DLOG(@"<show start sync>");
	}
	else if ([[notification name] isEqualToString:@"STOP_SYNC"])
	{
        //DLOG(@"<show stop sync>");
	}
}*/

@end
