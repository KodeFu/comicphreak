//
//  ContentViewController.h
//  Comic Phreak DB
//
//  Created by Mudit Vats on 2/25/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContentViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property NSString *comicFileName;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
- (IBAction)ButtonTwoPressed:(id)sender;

@end
