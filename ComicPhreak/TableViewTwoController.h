//
//  TableViewController.h
//  Comic Phreak DB
//
//  Created by Mudit Vats on 9/8/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate >

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
